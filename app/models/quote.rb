# Presupuesto para un cliente: líneas de producto (o libres) con precios SIN
# IVA, transporte y totales calculados; todo editable a mano.
class Quote < ApplicationRecord
  # Datos de la empresa tal y como aparecen en el PDF.
  COMPANY = {
    trade_name: "PHONE RELAX BAGS",
    legal_name: "Drop Point Systems S.L.U.",
    tax_id: "B02631976",
    address_lines: [ "Calle Carrasqueta Nº14", "P.I. Salinetas", "03610 Petrer (Alicante)" ],
    phone: "965371962",
    email: "phonerelaxstore@gmail.com",
    web: "www.phonerelax.com"
  }.freeze

  # Cuentas donde recibir el pago (la primera es la de siempre).
  BANK_ACCOUNTS = [
    "CAJAMAR ES41 3029 7241 2527 2000 9053",
    "BBVA ES65 0182 2961 3102 0170 2952"
  ].freeze

  # Transporte por defecto (sin IVA): la tarifa habitual de los presupuestos.
  DEFAULT_SHIPPING = BigDecimal("29.75")
  DEFAULT_PAYMENT_TERMS = "Pago a 30 días."
  DEFAULT_VALIDITY_DAYS = 15

  belongs_to :client
  has_many :quote_lines, dependent: :destroy, inverse_of: :quote

  accepts_nested_attributes_for :quote_lines, allow_destroy: true,
                                              reject_if: ->(attrs) { attrs["product_id"].blank? && attrs["description"].blank? }

  validates :issued_on, presence: true
  validates :shipping_cost, numericality: { greater_than_or_equal_to: 0 }

  # Cuenta donde se pide el pago (con respaldo a la histórica).
  def bank_account_display
    bank_account.presence || BANK_ACCOUNTS.first
  end

  before_validation :fill_lines_from_catalog
  before_create :assign_number

  scope :recent_first, -> { order(issued_on: :desc, id: :desc) }

  def active_lines
    quote_lines.reject(&:marked_for_destruction?)
  end

  # Total Oferta (sin IVA): líneas + transporte.
  def subtotal
    active_lines.sum(&:total) + shipping_cost
  end

  # Importe IVA: cada línea con su tipo; el transporte con el tipo general.
  def vat_amount
    lines_vat = active_lines.sum { |line| line.total * line.vat_rate / 100 }
    lines_vat + (shipping_cost * vat_rate / 100)
  end

  # Total Euros (IVA incluido).
  def total
    subtotal + vat_amount
  end

  private

  # Autocompleta las líneas con producto: descripción del catálogo y precio del
  # escalado según las unidades (solo lo que se dejó en blanco).
  def fill_lines_from_catalog
    quote_lines.each do |line|
      next if line.product.blank?

      line.description = line.product.name if line.description.blank?
      line.unit_price = PriceTier.price_for(line.product, line.quantity || 1) if line.unit_price.blank?
    end
  end

  # Nº de oferta tipo PR2608-0359 (PR + año/mes + 4 cifras).
  def assign_number
    self.number ||= loop do
      candidate = "PR#{Date.current.strftime('%y%m')}-#{format('%04d', SecureRandom.random_number(10_000))}"
      break candidate unless Quote.exists?(number: candidate)
    end
  end
end
