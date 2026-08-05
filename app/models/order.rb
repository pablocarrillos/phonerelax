class Order < ApplicationRecord
  # Solo se envía a países de la Unión Europea (nombre => código ISO para
  # validar teléfonos). España va primero, desdoblada en Península y Canarias
  # porque su transporte es distinto.
  EU_COUNTRY_CODES = {
    "España (Península)" => "ES", "España (Baleares)" => "ES", "España (Canarias)" => "ES",
    "Alemania" => "DE", "Austria" => "AT", "Bélgica" => "BE", "Bulgaria" => "BG",
    "Chequia" => "CZ", "Chipre" => "CY", "Croacia" => "HR", "Dinamarca" => "DK",
    "Eslovaquia" => "SK", "Eslovenia" => "SI", "Estonia" => "EE",
    "Finlandia" => "FI", "Francia" => "FR", "Grecia" => "GR", "Hungría" => "HU",
    "Irlanda" => "IE", "Italia" => "IT", "Letonia" => "LV", "Lituania" => "LT",
    "Luxemburgo" => "LU", "Malta" => "MT", "Países Bajos" => "NL", "Polonia" => "PL",
    "Portugal" => "PT", "Rumanía" => "RO", "Suecia" => "SE"
  }.freeze
  EU_COUNTRIES = EU_COUNTRY_CODES.keys.freeze
  # La «España» sin desdoblar de los pedidos y tarifas antiguos sigue siendo válida.
  LEGACY_COUNTRY_CODES = { "España" => "ES" }.freeze

  # Un pedido pendiente de pago se considera "antiguo" pasados estos días.
  STALE_UNPAID_DAYS = 3

  # --- Exención de IVA (facturación) ---
  # Interruptores, activos desde 08-2026 (empresa dada de alta en el ROI).
  #   EXPORT   → envío a Canarias: exportación exenta para CUALQUIER cliente
  #              (particular o empresa); hay que conservar el justificante de
  #              transporte de cada envío. El IGIC/DUA lo paga el destinatario.
  #   INTRA_EU → entrega intracomunitaria: solo B2B con NIF-IVA de otro país UE
  #              validado en VIES y mercancía enviada fuera de España (se declara
  #              en el modelo 349). Un particular de la UE paga IVA español.
  EXPORT_VAT_EXEMPTION_ENABLED = true
  INTRA_EU_VAT_EXEMPTION_ENABLED = true

  # Destinos que son exportación a efectos de IVA (pagan IGIC/IPSI en destino).
  EXPORT_COUNTRIES = [ "España (Canarias)" ].freeze

  # Prefijos telefónicos por país (ISO) para el selector del checkout: primero
  # los países de los idiomas de la web y después el resto de la UE.
  PHONE_PREFIXES = {
    "ES" => "+34", "PT" => "+351", "FR" => "+33", "GB" => "+44",
    "AT" => "+43", "BE" => "+32", "BG" => "+359", "CY" => "+357", "CZ" => "+420",
    "DE" => "+49", "DK" => "+45", "EE" => "+372", "FI" => "+358", "GR" => "+30",
    "HR" => "+385", "HU" => "+36", "IE" => "+353", "IT" => "+39", "LT" => "+370",
    "LU" => "+352", "LV" => "+371", "MT" => "+356", "NL" => "+31", "PL" => "+48",
    "RO" => "+40", "SE" => "+46", "SI" => "+386", "SK" => "+421"
  }.freeze
  # País del prefijo precargado según el idioma en que se navega.
  LOCALE_PHONE_COUNTRY = { "es" => "ES", "pt" => "PT", "en" => "GB", "fr" => "FR" }.freeze

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
  validates :country, inclusion: { in: EU_COUNTRIES + LEGACY_COUNTRY_CODES.keys, message: "debe ser un país de la Unión Europea" }
  validate :phone_matches_country

  # Si el cliente pide factura, los datos fiscales son obligatorios y el
  # identificador fiscal debe ser válido (NIF/CIF/NIE o NIF-IVA europeo).
  with_options if: :needs_invoice do
    validates :tax_name, :tax_id, :tax_address, :tax_city, :tax_postal_code, :tax_province, :tax_country, presence: true
    validate :tax_id_is_valid
  end

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

  # Precio del transporte: base del país de destino (configurable en el admin)
  # más el coste por unidad propio de cada producto enviado. Las tarifas se
  # guardan con IVA incluido; en una venta exenta se cobra el neto.
  def compute_shipping
    base = ShippingRate.base_for(country)
    gross = base + order_lines.sum { |line| line.product.shipping_unit_cost * line.quantity }
    vat_exempt? ? (gross / SHIPPING_VAT_FACTOR).round(2) : gross
  end
  SHIPPING_VAT_FACTOR = BigDecimal("1.21")

  # ¿Entrega intracomunitaria exenta? Empresa con NIF-IVA de otro país de la UE
  # verificado en VIES Y mercancía enviada fuera de España (si el envío se queda
  # en España la entrega no es intracomunitaria y lleva IVA).
  def intra_eu_business?
    needs_invoice && tax_id.present? && TaxId.eu_vat?(tax_id) &&
      TaxId.split_eu_vat(tax_id).first != "ES" && vies_valid == true &&
      EU_COUNTRY_CODES.merge(LEGACY_COUNTRY_CODES)[country] != "ES"
  end

  # Fija el tratamiento de IVA del pedido según el destino y los datos fiscales.
  # Se llama antes de montar las líneas, para que su precio unitario se congele
  # con o sin IVA según corresponda.
  def apply_vat_exemption!
    self.vat_exempt, self.vat_exempt_reason =
      if EXPORT_VAT_EXEMPTION_ENABLED && EXPORT_COUNTRIES.include?(country)
        [ true, "export" ]
      elsif INTRA_EU_VAT_EXEMPTION_ENABLED && intra_eu_business?
        [ true, "intra_eu" ]
      else
        [ false, nil ]
      end
  end

  # Desglose del IVA del pedido completo (líneas + transporte) para mostrarlo en
  # el proceso de compra: base imponible, cuota de IVA y tipo aplicado. `rate` es
  # el tipo como texto ("21", "0" si la venta es exenta) o nil si conviven varios
  # tipos distintos (hoy no ocurre: todo el catálogo va al 21%).
  def vat_breakdown
    return { base: total.to_d, vat: BigDecimal("0"), rate: "0" } if vat_exempt?

    vat = order_lines.sum do |line|
      subtotal = line.unit_price * line.quantity
      subtotal - subtotal / (1 + line.product.vat_percentage.to_d / 100)
    end
    vat += shipping_cost.to_d - shipping_cost.to_d / SHIPPING_VAT_FACTOR if shipping_cost.present?
    rates = order_lines.map { |line| line.product.vat_percentage.to_d }.uniq
    { base: total.to_d - vat.round(2), vat: vat.round(2),
      rate: rates.one? ? rates.first.to_s.sub(/\.0+\z/, "") : nil }
  end

  # ISO del prefijo del teléfono si ya está en formato internacional (para
  # repintar el selector del checkout). Prueba primero los prefijos más largos
  # para no confundir p. ej. +351 (PT) con +34 (ES).
  def phone_prefix_iso
    return nil unless phone.to_s.start_with?("+")

    PHONE_PREFIXES.sort_by { |_iso, prefix| -prefix.length }
                  .find { |_iso, prefix| phone.start_with?(prefix) }&.first
  end

  # Parte local del teléfono (sin el prefijo reconocido), para el campo de texto.
  def phone_without_prefix
    prefix = PHONE_PREFIXES[phone_prefix_iso]
    prefix ? phone.delete_prefix(prefix) : phone
  end

  def next_status
    return if pago_reembolsado? # un pedido reembolsado ya no avanza (no se envía)

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
      order_lines.includes(:product).each { |line| line.product.consume_stock!(line.quantity) }
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

  # Dinero cobrado que no se ha devuelto (para avisar antes de borrar).
  def unrefunded_amount
    pago_pagado? ? refundable_amount : 0
  end

  # Borra el pedido devolviendo al stock las unidades que se descontaron al
  # cobrarse (pagados y reembolsados); los pendientes nunca descontaron stock.
  # OJO: borrar NO reembolsa el dinero: eso se hace antes, si procede.
  def destroy_restoring_stock!
    transaction do
      unless pago_pendiente?
        order_lines.includes(:product).each { |line| line.product.restore_stock!(line.quantity) }
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

  # El identificador fiscal debe ser un NIF/CIF/NIE español válido o un NIF-IVA
  # europeo con formato correcto.
  def tax_id_is_valid
    return if tax_id.blank?

    errors.add(:tax_id, "no es un NIF/CIF/NIE ni un NIF-IVA europeo válido") unless TaxId.valid?(tax_id)
  end

  # El teléfono debe ser válido: con prefijo internacional («+») vale el de
  # cualquier país (el cliente puede vivir en un país distinto al de envío);
  # sin prefijo, debe ser un número válido del país de envío.
  def phone_matches_country
    return if phone.blank?

    if phone.start_with?("+")
      errors.add(:phone, "no parece un número de teléfono válido") unless Phonelib.valid?(phone)
      return
    end

    code = EU_COUNTRY_CODES[country] || LEGACY_COUNTRY_CODES[country]
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
