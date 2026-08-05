# Presupuesto para un cliente: líneas de producto (o libres) con precios SIN
# IVA, transporte y totales calculados; todo editable a mano.
class Quote < ApplicationRecord
  # Datos de la empresa tal y como aparecen en el PDF.
  COMPANY = {
    legal_name: "Drop Point Systems S.L.U.",
    tax_id: "B02631976",
    address_lines: [ "Calle Carrasqueta Nº14", "P.I. Salinetas", "03610 Petrer (Alicante)" ],
    phone: "965371962",
    email: "phonerelaxstore@gmail.com", # comprobantes de transferencia
    footer_email: "info@phonerelax.com", # correo público del pie del PDF
    web: "www.phonerelax.com"
  }.freeze

  # Cuentas donde recibir el pago (la primera es la de siempre).
  BANK_ACCOUNTS = [
    "CAJAMAR ES41 3029 7241 2527 2000 9053",
    "BBVA ES65 0182 2961 3102 0170 2952"
  ].freeze

  # Transporte por defecto (sin IVA): la tarifa habitual de los presupuestos.
  DEFAULT_SHIPPING = BigDecimal("29.75")
  DEFAULT_PAYMENT_TERMS = "50% IVA incluido para confirmar y 50% a la entrega."
  DEFAULT_VALIDITY_DAYS = 15

  belongs_to :client
  has_many :quote_lines, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :quote

  # Solo se descartan filas NUEVAS vacías; las existentes (con id) siempre se procesan.
  accepts_nested_attributes_for :quote_lines, allow_destroy: true,
                                              reject_if: ->(attrs) { attrs["id"].blank? && attrs["product_id"].blank? && attrs["description"].blank? }

  validates :issued_on, presence: true
  validates :delivery_terms, presence: true
  validates :shipping_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validate :must_have_lines

  # Cuenta donde se pide el pago (con respaldo a la histórica).
  def bank_account_display
    bank_account.presence || BANK_ACCOUNTS.first
  end

  # Transporte según la configuración de Transporte (base del país de envío +
  # coste por unidad de cada producto), pasado a SIN IVA con el tipo del
  # transporte. Es el valor que el editor propone; se puede fijar a mano.
  def computed_shipping
    gross = ShippingRate.base_for(shipping_country.presence || "España") +
            active_lines.sum { |line| line.product ? line.product.shipping_unit_cost * line.quantity.to_i : 0 }
    (gross / (1 + (vat_rate.to_d / 100))).round(2)
  end

  before_validation :fill_lines_from_catalog
  before_create :assign_number

  scope :recent_first, -> { order(issued_on: :desc, id: :desc) }

  def active_lines
    quote_lines.reject(&:marked_for_destruction?)
  end

  # ¿Alguna línea usa descuento? (decide si el documento muestra esa columna)
  def line_discounts?
    active_lines.any?(&:discounted?)
  end

  def lines_total
    active_lines.sum(&:total)
  end

  # Descuento global sobre las líneas (el transporte no se descuenta).
  def discount_amount
    (lines_total * (discount_percent.to_d / 100)).round(2)
  end

  # Total Oferta (sin IVA): líneas − descuento global + transporte.
  def subtotal
    lines_total - discount_amount + shipping_cost
  end

  # Importe IVA: cada línea con su tipo (el descuento global reduce la base
  # proporcionalmente); el transporte con el tipo general.
  def vat_amount
    lines_vat = active_lines.sum { |line| line.total * line.vat_rate / 100 }
    (lines_vat * (1 - (discount_percent.to_d / 100))) + (shipping_cost * vat_rate / 100)
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

      line.description = line.product.name if line.description.blank? || (line.persisted? && line.will_save_change_to_product_id?)
      line.unit_price = PriceTier.price_for(line.product, line.quantity || 1) if line.unit_price.blank?
    end
  end

  # Un presupuesto sin productos no tiene sentido (el transporte no cuenta).
  def must_have_lines
    errors.add(:base, "El presupuesto necesita al menos una línea de producto") if active_lines.empty?
  end

  # Nº de oferta tipo PR2608-0359 (PR + año/mes + 4 cifras).
  def assign_number
    self.number ||= loop do
      candidate = "PR#{Date.current.strftime('%y%m')}-#{format('%04d', SecureRandom.random_number(10_000))}"
      break candidate unless Quote.exists?(number: candidate)
    end
  end
end
