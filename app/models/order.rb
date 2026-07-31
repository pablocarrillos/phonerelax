class Order < ApplicationRecord
  # Tarifa de transporte (precios con IVA incluido): base para 1-10 bolsas,
  # más un euro por cada bolsa o imán, y recargo fuera de España.
  SHIPPING_BASE = BigDecimal('5.95')
  SHIPPING_PER_UNIT = BigDecimal('1')
  SHIPPING_FOREIGN_SURCHARGE = BigDecimal('8')

  # Solo se envía a países de la Unión Europea (nombre => código ISO para validar teléfonos).
  EU_COUNTRY_CODES = {
    'Alemania' => 'DE', 'Austria' => 'AT', 'Bélgica' => 'BE', 'Bulgaria' => 'BG',
    'Chequia' => 'CZ', 'Chipre' => 'CY', 'Croacia' => 'HR', 'Dinamarca' => 'DK',
    'Eslovaquia' => 'SK', 'Eslovenia' => 'SI', 'España' => 'ES', 'Estonia' => 'EE',
    'Finlandia' => 'FI', 'Francia' => 'FR', 'Grecia' => 'GR', 'Hungría' => 'HU',
    'Irlanda' => 'IE', 'Italia' => 'IT', 'Letonia' => 'LV', 'Lituania' => 'LT',
    'Luxemburgo' => 'LU', 'Malta' => 'MT', 'Países Bajos' => 'NL', 'Polonia' => 'PL',
    'Portugal' => 'PT', 'Rumanía' => 'RO', 'Suecia' => 'SE'
  }.freeze
  EU_COUNTRIES = EU_COUNTRY_CODES.keys.freeze

  has_many :order_lines, dependent: :destroy
  has_many :products, through: :order_lines
  has_many :order_events, dependent: :destroy

  # Estado logístico del pedido, gestionado a mano desde el admin.
  enum :status, { creado: 0, enviado: 1, recibido: 2 }
  # Estado del cobro, gestionado por Stripe (webhook / retorno del Checkout).
  enum :payment_status, { pendiente: 0, pagado: 1 }, prefix: :pago

  validates :customer_name, :email, :address, :city, :postal_code, :country, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country, inclusion: { in: EU_COUNTRIES, message: 'debe ser un país de la Unión Europea' }
  validate :phone_matches_country

  before_create :assign_number
  after_create { order_events.create!(event: 'creado') }

  scope :recent_first, -> { order(created_at: :desc) }
  # Búsqueda del admin por número de pedido o datos del cliente.
  scope :search, lambda { |term|
    next if term.blank?

    like = "%#{sanitize_sql_like(term.strip)}%"
    where('number ILIKE :q OR customer_name ILIKE :q OR email ILIKE :q OR phone ILIKE :q OR city ILIKE :q OR country ILIKE :q', q: like)
  }

  # Total en euros calculado a partir de las líneas; se congela en el pedido al confirmarse.
  def compute_total
    order_lines.sum { |line| line.unit_price * line.quantity }
  end

  # Precio del transporte según la dirección y las unidades del pedido.
  def compute_shipping
    units = order_lines.sum(&:quantity)
    cost = SHIPPING_BASE + (SHIPPING_PER_UNIT * units)
    cost += SHIPPING_FOREIGN_SURCHARGE unless country == 'España'
    cost
  end

  def next_status
    { 'creado' => 'enviado', 'enviado' => 'recibido' }[status]
  end

  # Marca el pago y descuenta stock una sola vez (webhook y retorno del Checkout
  # pueden llegar los dos).
  def mark_paid!
    return if pago_pagado?

    transaction do
      update!(payment_status: :pagado)
      order_events.create!(event: 'pagado')
      order_lines.includes(:product).each do |line|
        line.product.update!(stock: [line.product.stock - line.quantity, 0].max)
      end
    end
  end

  # Avanza el estado logístico dejando rastro en el histórico.
  def advance_status!
    return unless next_status

    transaction do
      update!(status: next_status)
      order_events.create!(event: status)
    end
  end

  private

  # El teléfono, si se indica, debe ser válido para el país de envío (ni cortos ni largos).
  def phone_matches_country
    return if phone.blank?

    code = EU_COUNTRY_CODES[country]
    return if Phonelib.valid_for_country?(phone, code)

    errors.add(:phone, "no parece un número válido de #{country || 'ese país'}")
  end

  # Número corto legible para el cliente, p. ej. PR-24J7X9.
  def assign_number
    self.number ||= loop do
      candidate = "PR-#{SecureRandom.alphanumeric(6).upcase}"
      break candidate unless Order.exists?(number: candidate)
    end
  end
end
