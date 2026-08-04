class Order < ApplicationRecord
  # Tarifa de transporte (precios con IVA incluido): base para 1-10 bolsas,
  # más un euro por cada bolsa o imán, y recargo fuera de España.
  SHIPPING_BASE = BigDecimal("5.95")
  SHIPPING_PER_UNIT = BigDecimal("1")
  SHIPPING_FOREIGN_SURCHARGE = BigDecimal("8")

  # Solo se envía a países de la Unión Europea (nombre => código ISO para validar teléfonos).
  EU_COUNTRY_CODES = {
    "Alemania" => "DE", "Austria" => "AT", "Bélgica" => "BE", "Bulgaria" => "BG",
    "Chequia" => "CZ", "Chipre" => "CY", "Croacia" => "HR", "Dinamarca" => "DK",
    "Eslovaquia" => "SK", "Eslovenia" => "SI", "España" => "ES", "Estonia" => "EE",
    "Finlandia" => "FI", "Francia" => "FR", "Grecia" => "GR", "Hungría" => "HU",
    "Irlanda" => "IE", "Italia" => "IT", "Letonia" => "LV", "Lituania" => "LT",
    "Luxemburgo" => "LU", "Malta" => "MT", "Países Bajos" => "NL", "Polonia" => "PL",
    "Portugal" => "PT", "Rumanía" => "RO", "Suecia" => "SE"
  }.freeze
  EU_COUNTRIES = EU_COUNTRY_CODES.keys.freeze

  # Un pedido pendiente de pago se considera "antiguo" pasados estos días.
  STALE_UNPAID_DAYS = 3

  # Plantillas de URL de seguimiento por transportista (se detecta por el nombre).
  CARRIER_TRACKING_URLS = {
    "correos" => "https://www.correos.es/es/es/herramientas/localizador/envios/detalle?tracking-number=%s",
    "seur"    => "https://www.seur.com/livetracking/?segOnlineIdentificador=%s",
    "mrw"     => "https://www.mrw.es/_mrw/seguimiento_envios.asp?enviament=%s",
    "nacex"   => "https://www.nacex.es/seguimientoDetalle.do?numero_albaran=%s",
    "gls"     => "https://mygls.gls-spain.es/e/%s",
    "dhl"     => "https://www.dhl.com/es-es/home/tracking.html?tracking-id=%s",
    "ups"     => "https://www.ups.com/track?tracknum=%s",
    "fedex"   => "https://www.fedex.com/fedextrack/?trknbr=%s"
  }.freeze

  has_many :order_lines, dependent: :destroy
  has_many :products, through: :order_lines
  has_many :order_events, dependent: :destroy

  # Estado logístico del pedido, gestionado a mano desde el admin.
  enum :status, { creado: 0, enviado: 1, recibido: 2 }
  # Estado del cobro, gestionado por Stripe (webhook / retorno del Checkout).
  # "reembolsado" = devuelto íntegramente al cliente (desde el admin).
  enum :payment_status, { pendiente: 0, pagado: 1, reembolsado: 2 }, prefix: :pago

  validates :customer_name, :email, :phone, :address, :city, :postal_code, :province, :country, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country, inclusion: { in: EU_COUNTRIES, message: "debe ser un país de la Unión Europea" }
  validate :phone_matches_country

  before_create :assign_number
  after_create { order_events.create!(event: "creado") }

  scope :recent_first, -> { order(created_at: :desc) }
  # Pendientes de pago desde hace más de STALE_UNPAID_DAYS días.
  scope :stale_unpaid, -> { pago_pendiente.where(created_at: ..STALE_UNPAID_DAYS.days.ago) }
  # Búsqueda del admin por número de pedido o datos del cliente.
  scope :search, lambda { |term|
    next if term.blank?

    like = "%#{sanitize_sql_like(term.strip)}%"
    where("number ILIKE :q OR customer_name ILIKE :q OR email ILIKE :q OR phone ILIKE :q OR city ILIKE :q OR country ILIKE :q", q: like)
  }

  # Total en euros calculado a partir de las líneas; se congela en el pedido al confirmarse.
  def compute_total
    order_lines.sum { |line| line.unit_price * line.quantity }
  end

  # Precio del transporte según la dirección y las unidades del pedido.
  def compute_shipping
    units = order_lines.sum(&:quantity)
    cost = SHIPPING_BASE + (SHIPPING_PER_UNIT * units)
    cost += SHIPPING_FOREIGN_SURCHARGE unless country == "España"
    cost
  end

  def next_status
    { "creado" => "enviado", "enviado" => "recibido" }[status]
  end

  # URL de seguimiento del transportista, si el nº y el transportista se reconocen.
  def tracking_url
    return if tracking_number.blank? || tracking_carrier.blank?

    key = tracking_carrier.downcase
    template = CARRIER_TRACKING_URLS.find { |name, _| key.include?(name) }&.last
    format(template, CGI.escape(tracking_number)) if template
  end

  def previous_status
    { "enviado" => "creado", "recibido" => "enviado" }[status]
  end

  # Marca el pago y descuenta stock una sola vez (webhook y retorno del Checkout
  # pueden llegar los dos). `manual: true` para cobros fuera de Stripe (transferencia,
  # efectivo…) que registra el admin.
  def mark_paid!(manual: false)
    return if pago_pagado?

    transaction do
      update!(payment_status: :pagado, paid_manually: manual)
      order_events.create!(event: manual ? "pagado (manual)" : "pagado")
      order_lines.includes(:product).each do |line|
        line.product.update!(stock: [ line.product.stock - line.quantity, 0 ].max)
      end
    end
    OrderMailer.paid(self).deliver_later
    OrderMailer.new_sale(self).deliver_later
  end

  # Importe cobrado al cliente: el total se congela con el transporte incluido
  # al confirmarse el pedido.
  def amount_paid
    total.to_d
  end

  # Lo que queda por devolver tras los reembolsos ya hechos.
  def refundable_amount
    amount_paid - refunded_amount
  end

  # ¿Se puede borrar? Nunca con dinero cobrado sin devolver: los pagados (en
  # cualquier estado logístico) exigen reembolsar antes.
  def deletable?
    pago_pendiente? || pago_reembolsado?
  end

  # Borra el pedido devolviendo al stock las unidades que se descontaron al
  # cobrarse. Los pendientes de pago nunca descontaron stock, así que no suman.
  def destroy_restoring_stock!
    raise ArgumentError, "No se puede borrar un pedido con dinero cobrado; reembólsalo antes" unless deletable?

    transaction do
      if pago_reembolsado?
        order_lines.includes(:product).each { |line| line.product.increment!(:stock, line.quantity) }
      end
      destroy!
    end
  end

  # Reembolsa `amount` euros (parcial o total). Los pagos de Stripe se devuelven
  # allí (a la tarjeta del cliente); los cobros manuales solo se registran. Cuando
  # lo devuelto alcanza lo cobrado, el pedido pasa a "reembolsado".
  def refund!(amount)
    amount = BigDecimal(amount.to_s)
    raise ArgumentError, "Este pedido no tiene ningún cobro que reembolsar" unless pago_pagado?
    raise ArgumentError, "El importe debe ser mayor que cero" if amount <= 0
    raise ArgumentError, "El importe supera lo pendiente de devolver" if amount > refundable_amount

    if stripe_session_id.present? && !paid_manually?
      self.stripe_payment_intent_id ||= Stripe::Checkout::Session.retrieve(stripe_session_id).payment_intent
      Stripe::Refund.create(payment_intent: stripe_payment_intent_id, amount: (amount * 100).to_i)
    end

    transaction do
      self.refunded_amount += amount
      self.payment_status = :reembolsado if refunded_amount >= amount_paid
      save!
      order_events.create!(event: pago_reembolsado? ? "reembolsado" : "reembolso parcial (#{format('%.2f', amount)} €)")
    end
  end

  # Avanza el estado logístico dejando rastro en el histórico. Al pasar a "enviado"
  # guarda, si se indican, el transportista y el número de seguimiento.
  def advance_status!(tracking_number: nil, tracking_carrier: nil)
    return unless next_status

    transaction do
      attrs = { status: next_status }
      if next_status == "enviado"
        attrs[:tracking_number]  = tracking_number.presence  if tracking_number
        attrs[:tracking_carrier] = tracking_carrier.presence if tracking_carrier
      end
      update!(attrs)
      order_events.create!(event: status)
    end
    OrderMailer.shipped(self).deliver_later if enviado?
  end

  # Revierte el estado logístico un paso (para deshacer un avance por error).
  def revert_status!
    target = previous_status
    return unless target

    transaction do
      update!(status: target)
      order_events.create!(event: "revertido a #{target}")
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
