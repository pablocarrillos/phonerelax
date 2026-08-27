# Presupuesto para un cliente: líneas de producto (o libres) con precios SIN
# IVA, transporte y totales calculados; todo editable a mano.
class Quote < ApplicationRecord
  # Datos de la empresa tal y como aparecen en el PDF.
  COMPANY = {
    legal_name: "Drop Point Systems S.L.U.",
    tax_id: "B02631976",
    address_lines: [ "C/ Carrasqueta, 14", "Pol. Ind. Salinetas", "Petrer 03610 (Alicante) España" ],
    phone: "965371962",
    email: "info@phonerelax.com", # comprobantes de transferencia
    footer_email: "info@phonerelax.com", # correo público del pie del PDF
    web: "www.phonerelax.com"
  }.freeze

  # Cuentas donde recibir el pago (la primera es la de siempre).
  BANK_ACCOUNTS = [
    "CAJAMAR ES41 3029 7241 2527 2000 9053",
    "BBVA ES65 0182 2961 3102 0170 2952"
  ].freeze

  # Cuenta que se propone al crear un presupuesto nuevo (BBVA).
  DEFAULT_BANK_ACCOUNT = BANK_ACCOUNTS.find { |a| a.include?("BBVA") } || BANK_ACCOUNTS.first

  # Transporte por defecto (sin IVA): la tarifa habitual de los presupuestos.
  DEFAULT_SHIPPING = BigDecimal("29.75")
  DEFAULT_PAYMENT_TERMS = "50% IVA incluido para confirmar y 50% a la entrega."
  DEFAULT_VALIDITY_DAYS = 15

  belongs_to :client
  has_many :quote_lines, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :quote
  # Muestras enviadas vinculadas a este presupuesto (al borrarlo se desvinculan).
  has_many :samples, dependent: :nullify
  # líneas de compras a proveedor imputadas a este presupuesto (sus costes)
  has_many :purchase_lines, dependent: :nullify
  # comentarios del seguimiento comercial, con su fecha y su usuario
  has_many :comments, class_name: "QuoteComment", dependent: :destroy, inverse_of: :quote

  # Estado del seguimiento comercial del presupuesto.
  enum :status, { abierto: 0, aprobado: 1, en_pausa: 2, perdido: 3, entregado: 4, enviado: 5 }

  STATUS_LABELS = { "abierto" => "Abierto", "enviado" => "Enviado", "aprobado" => "Aprobado", "en_pausa" => "En pausa",
                    "perdido" => "Perdido", "entregado" => "Entregado" }.freeze

  def status_label
    STATUS_LABELS[status] || status
  end

  # ¿El presupuesto se convirtió en pedido? (aprobado o ya entregado):
  # habilita el cobro y los ficheros del pedido.
  def confirmed?
    aprobado? || entregado?
  end

  # Seguimiento del cobro (las condiciones habituales son 50 % para confirmar
  # y 50 % a la entrega).
  enum :payment_status, { sin_pagos: 0, pagado_confirmar: 1, pagado_total: 2 }

  PAYMENT_LABELS = { "sin_pagos" => "Sin pagos", "pagado_confirmar" => "Pagado para confirmar", "pagado_total" => "Pagado totalmente" }.freeze

  def payment_status_label
    PAYMENT_LABELS[payment_status] || payment_status
  end

  # Ficheros del pedido una vez aprobado el presupuesto.
  ATTACHMENTS = {
    "school_logo" => "Logo",
    "dtf_file" => "Fichero DTF",
    "approved_sample" => "Imagen de muestra aprobada",
    "signed_quote" => "Presupuesto firmado (PDF)"
  }.freeze

  has_one_attached :school_logo
  has_one_attached :dtf_file
  has_one_attached :approved_sample
  has_one_attached :signed_quote

  # Adjunto por nombre, con despacho explícito (nunca send con datos del usuario).
  def order_file(name)
    case name.to_s
    when "school_logo" then school_logo
    when "dtf_file" then dtf_file
    when "approved_sample" then approved_sample
    when "signed_quote" then signed_quote
    else raise ArgumentError, "adjunto desconocido: #{name}"
    end
  end

  # ¿Lleva personalización DTF entre sus líneas?
  def dtf_lines?
    quote_lines.any? { |line| line.product && line.product.dtf_units.positive? }
  end

  # Adjuntos que aplican a este presupuesto: la imagen de muestra aprobada solo
  # con personalización DTF (o si ya está subida, para no dejarla inaccesible).
  # Los ficheros de personalización (logo, fichero DTF, muestra) solo aparecen si
  # el presupuesto contrata «Personalización DTF» (o ya tienen algo subido); el
  # presupuesto firmado se muestra siempre.
  def available_files
    ATTACHMENTS.keys.select { |name| name == "signed_quote" || dtf_lines? || order_file(name).attached? }
  end

  # Solo se descartan filas NUEVAS vacías; las existentes (con id) siempre se procesan.
  accepts_nested_attributes_for :quote_lines, allow_destroy: true,
                                              reject_if: ->(attrs) { attrs["id"].blank? && attrs["product_id"].blank? && attrs["description"].blank? }

  validates :issued_on, presence: true
  validates :delivery_terms, presence: true
  # El nº de oferta se puede editar: único siempre y obligatorio al editar (en
  # los nuevos, si se deja vacío se genera automáticamente).
  before_validation { self.number = number.strip.presence if number }
  validates :number, uniqueness: true, allow_blank: true
  validates :number, presence: true, on: :update
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

  # Coste total en euros de las compras a proveedor imputadas a este presupuesto.
  def imputed_cost_eur
    purchase_lines.includes(:purchase).sum(&:total_eur)
  end

  # --- Margen estimado ---
  # Base de venta sobre la que se calcula el margen: las líneas con su
  # descuento, SIN el transporte (que no es margen: se repercute al cliente).
  def lines_base
    lines_total - discount_amount
  end

  # Coste de los productos vendidos, al coste real medio de compra (precio +
  # transporte, aduanas y otros, prorrateados). Las unidades que ya cubre una
  # compra imputada a este presupuesto NO se cuentan otra vez: su coste real ya
  # está en imputed_cost_eur.
  def product_cost_eur(landed_costs = Purchase.received.average_landed_costs)
    imputed_units = purchase_lines.where.not(product_id: nil).group(:product_id).sum(:quantity)

    active_lines.sum(BigDecimal("0")) do |line|
      data = line.product && landed_costs[line.product]
      next BigDecimal("0") unless data

      pending = line.quantity.to_i - imputed_units[line.product_id].to_i
      pending.positive? ? data[:avg_cost] * pending : BigDecimal("0")
    end
  end

  # Coste estimado del pedido: lo comprado para él más el coste de los
  # productos de catálogo que se sirven de stock.
  def estimated_cost_eur(landed_costs = Purchase.received.average_landed_costs)
    imputed_cost_eur + product_cost_eur(landed_costs)
  end

  # Beneficio estimado (sin IVA y sin transporte) y su porcentaje sobre la base.
  def estimated_margin_eur(landed_costs = Purchase.received.average_landed_costs)
    (lines_base - estimated_cost_eur(landed_costs)).round(2)
  end

  def estimated_margin_percent(landed_costs = Purchase.received.average_landed_costs)
    return nil if lines_base.to_d.zero?

    (estimated_margin_eur(landed_costs) / lines_base * 100).round(1)
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
