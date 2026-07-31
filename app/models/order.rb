class Order < ApplicationRecord
  # Solo se envía a países de la Unión Europea.
  EU_COUNTRIES = [
    'Alemania', 'Austria', 'Bélgica', 'Bulgaria', 'Chequia', 'Chipre', 'Croacia',
    'Dinamarca', 'Eslovaquia', 'Eslovenia', 'España', 'Estonia', 'Finlandia',
    'Francia', 'Grecia', 'Hungría', 'Irlanda', 'Italia', 'Letonia', 'Lituania',
    'Luxemburgo', 'Malta', 'Países Bajos', 'Polonia', 'Portugal', 'Rumanía', 'Suecia'
  ].freeze

  has_many :order_lines, dependent: :destroy
  has_many :products, through: :order_lines

  # Estado logístico del pedido, gestionado a mano desde el admin.
  enum :status, { creado: 0, enviado: 1, recibido: 2 }
  # Estado del cobro, gestionado por Stripe (webhook / retorno del Checkout).
  enum :payment_status, { pendiente: 0, pagado: 1 }, prefix: :pago

  validates :customer_name, :email, :address, :city, :postal_code, :country, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country, inclusion: { in: EU_COUNTRIES, message: 'debe ser un país de la Unión Europea' }

  before_create :assign_number

  scope :recent_first, -> { order(created_at: :desc) }

  # Total en euros calculado a partir de las líneas; se congela en el pedido al confirmarse.
  def compute_total
    order_lines.sum { |line| line.unit_price * line.quantity }
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
      order_lines.includes(:product).each do |line|
        line.product.update!(stock: [line.product.stock - line.quantity, 0].max)
      end
    end
  end

  private

  # Número corto legible para el cliente, p. ej. PR-24J7X9.
  def assign_number
    self.number ||= loop do
      candidate = "PR-#{SecureRandom.alphanumeric(6).upcase}"
      break candidate unless Order.exists?(number: candidate)
    end
  end
end
