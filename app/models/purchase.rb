# Compra a un proveedor: líneas de producto más los costes asociados
# (transporte, aduanas…), con su factura en PDF. Al marcarse como recibida
# suma las unidades al stock.
class Purchase < ApplicationRecord
  belongs_to :supplier
  has_many :purchase_lines, dependent: :destroy, inverse_of: :purchase
  has_one_attached :invoice

  accepts_nested_attributes_for :purchase_lines, allow_destroy: true,
                                                 reject_if: ->(attrs) { attrs["product_id"].blank? }

  validates :ordered_on, presence: true
  validates :shipping_cost, :customs_cost, :other_costs,
            numericality: { greater_than_or_equal_to: 0 }

  CURRENCIES = %w[EUR USD].freeze
  validates :currency, inclusion: { in: CURRENCIES }

  # Al guardar en USD con fecha de factura, fija el tipo de cambio de ese día.
  before_save :set_exchange_rate

  scope :recent_first, -> { order(ordered_on: :desc, id: :desc) }
  scope :received, -> { where.not(received_on: nil) }

  def received?
    received_on.present?
  end

  def usd?
    currency == "USD"
  end

  # Euros por cada unidad de la moneda de la compra: 1 si ya está en EUR; si es
  # USD, el tipo de cambio USD→EUR fijado en la fecha de factura (1 si falta).
  def eur_rate
    usd? ? (exchange_rate || BigDecimal("1")) : BigDecimal("1")
  end

  # Suma de las líneas (sin costes adicionales).
  def lines_total
    purchase_lines.sum { |line| line.unit_cost * line.quantity }
  end

  # Costes adicionales repartibles: transporte + aduanas + otros.
  def extra_costs
    shipping_cost + customs_cost + other_costs
  end

  def total_cost
    lines_total + extra_costs
  end

  # Coste total ya convertido a euros (la moneda base del negocio).
  def total_cost_eur
    total_cost * eur_rate
  end

  # Coste real («aterrizado») de una unidad de la línea, EN EUROS: su coste de
  # compra más la parte proporcional de los costes adicionales según el peso de
  # la línea, convertido a euros con el tipo de cambio de la compra.
  def landed_unit_cost(line)
    base =
      if lines_total.zero?
        line.unit_cost
      else
        line_subtotal = line.unit_cost * line.quantity
        share = extra_costs * (line_subtotal / lines_total)
        line.unit_cost + (share / line.quantity)
      end
    base * eur_rate
  end

  # Marca la compra como recibida y suma las unidades al stock (una sola vez).
  def receive!
    return if received?

    transaction do
      update!(received_on: Date.current)
      purchase_lines.includes(:product).each { |line| line.product.increment!(:stock, line.quantity) }
    end
  end

  # Deshace la recepción (p. ej. marcada por error) restando lo sumado.
  def unreceive!
    return unless received?

    transaction do
      update!(received_on: nil)
      purchase_lines.includes(:product).each do |line|
        line.product.update!(stock: [ line.product.stock - line.quantity, 0 ].max)
      end
    end
  end

  # Coste real medio por unidad de cada producto, ponderado por unidades,
  # contando solo compras recibidas. => { product => { units:, avg_cost: } }
  def self.average_landed_costs
    result = {}
    received.includes(purchase_lines: :product).find_each do |purchase|
      purchase.purchase_lines.each do |line|
        entry = result[line.product] ||= { units: 0, cost: BigDecimal("0") }
        entry[:units] += line.quantity
        entry[:cost] += purchase.landed_unit_cost(line) * line.quantity
      end
    end
    result.transform_values { |e| { units: e[:units], avg_cost: e[:cost] / e[:units] } }
  end

  private

  # Consulta y fija el tipo de cambio USD→EUR de la fecha de factura cuando la
  # compra está en dólares. En EUR se limpia. Si la API falla, se deja el valor
  # anterior (o el que se haya introducido a mano) sin bloquear el guardado.
  def set_exchange_rate
    if usd? && invoice_date.present?
      if exchange_rate.blank? || will_save_change_to_invoice_date? || will_save_change_to_currency?
        rate = ExchangeRate.usd_to_eur(invoice_date)
        self.exchange_rate = rate if rate
      end
    else
      self.exchange_rate = nil
    end
  end
end
