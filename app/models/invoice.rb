# Factura emitida desde Contabilidad: de una venta web (Order pagado) o de un
# presupuesto aprobado (Quote). Los datos del cliente y los importes se copian
# al emitir para que la factura no cambie aunque el origen se edite después.
class Invoice < ApplicationRecord
  WEB = "web"
  QUOTE = "quote"
  KINDS = [ WEB, QUOTE ].freeze

  belongs_to :order, optional: true
  belongs_to :quote, optional: true
  has_many :lines, -> { order(:position) },
           class_name: "InvoiceLine", dependent: :destroy, inverse_of: :invoice

  validates :number, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validates :client_name, :issued_on, presence: true

  scope :recent_first, -> { order(issued_on: :desc, id: :desc) }

  # VERI*FACTU: al emitirse se encola el alta (si está activado en ajustes).
  after_create_commit :enqueue_verifactu_submission

  def verifactu_sent? = verifactu_status == "sent"
  def verifactu_pending? = verifactu_status == "pending"
  def verifactu_error? = verifactu_status == "error"

  def submit_to_verifactu!
    update_column(:verifactu_status, "pending") unless verifactu_sent?
    Verifactu::SubmitInvoiceJob.perform_later(self)
  end

  # Emite (idempotente) la factura de una venta web pagada.
  def self.issue_for_order!(order)
    existing = find_by(order: order)
    return existing if existing
    raise ArgumentError, "El pedido #{order.number} no está pagado" unless order.pago_pagado?

    breakdown = order.vat_breakdown
    transaction do
      invoice = create!(
        number: CompanySetting.current.take_number!(WEB), kind: WEB, order: order,
        issued_on: Date.current,
        client_name: order.customer_name, client_tax_id: order.tax_id.presence,
        client_email: order.email,
        client_address: [ order.address, [ order.postal_code, order.city ].compact_blank.join(" "),
                          [ order.province, order.country ].compact_blank.join(" · ") ].compact_blank.join("\n"),
        subtotal: breakdown[:base], vat_amount: breakdown[:vat], total: order.total,
        vat_lines: order_vat_lines(order)
      )
      order.order_lines.each_with_index do |line, index|
        invoice.lines.create!(description: line.product.name, quantity: line.quantity,
                              unit_price: line.unit_price, total: line.unit_price * line.quantity,
                              position: index)
      end
      if order.shipping_cost.to_d.positive?
        invoice.lines.create!(description: "Transporte", quantity: 1,
                              unit_price: order.shipping_cost, total: order.shipping_cost,
                              position: order.order_lines.size)
      end
      invoice
    end
  end

  # Emite (idempotente) la factura de un presupuesto aprobado o entregado.
  def self.issue_for_quote!(quote)
    existing = find_by(quote: quote)
    return existing if existing
    unless %w[aprobado entregado].include?(quote.status)
      raise ArgumentError, "El presupuesto #{quote.number} no está aprobado"
    end

    client = quote.client
    transaction do
      invoice = create!(
        number: CompanySetting.current.take_number!(QUOTE), kind: QUOTE, quote: quote,
        issued_on: Date.current,
        client_name: client.name, client_tax_id: client.tax_id.presence,
        client_email: client.email.presence, client_address: client.address,
        subtotal: quote.subtotal, vat_amount: quote.vat_amount, total: quote.total,
        vat_lines: quote_vat_lines(quote)
      )
      discount_factor = 1 - (quote.discount_percent.to_d / 100)
      quote.active_lines.each_with_index do |line, index|
        invoice.lines.create!(description: line.description, quantity: line.quantity,
                              unit_price: line.unit_price,
                              total: (line.total * discount_factor).round(2), position: index)
      end
      if quote.shipping_cost.to_d.positive?
        invoice.lines.create!(description: "Transporte", quantity: 1,
                              unit_price: quote.shipping_cost, total: quote.shipping_cost,
                              position: quote.active_lines.size)
      end
      invoice
    end
  end

  # Datos para el PDF (misma forma para factura emitida y previsualización).
  def pdf_data
    {
      number: number, provisional: false, issued_on: issued_on,
      client_name: client_name, client_tax_id: client_tax_id, client_address: client_address,
      lines: lines.map { |l| { description: l.description, quantity: l.quantity, unit_price: l.unit_price, total: l.total } },
      vat_lines: vat_lines, subtotal: subtotal, vat_amount: vat_amount, total: total,
      verifactu_qr: verifactu_qr, verifactu_huella: verifactu_huella, verifactu_url: verifactu_url
    }
  end

  # Previsualización de la factura de un pedido web, sin guardar nada.
  def self.preview_for_order(order)
    breakdown = order.vat_breakdown
    lines = order.order_lines.map do |line|
      { description: line.product.name, quantity: line.quantity,
        unit_price: line.unit_price, total: line.unit_price * line.quantity }
    end
    lines << { description: "Transporte", quantity: 1, unit_price: order.shipping_cost, total: order.shipping_cost } if order.shipping_cost.to_d.positive?
    { number: CompanySetting.current.preview_number(WEB), provisional: true, issued_on: Date.current,
      client_name: order.customer_name, client_tax_id: order.tax_id.presence, client_address: order.address,
      lines: lines, vat_lines: order_vat_lines(order),
      subtotal: breakdown[:base], vat_amount: breakdown[:vat], total: order.total }
  end

  # Previsualización de la factura de un presupuesto, sin guardar nada.
  def self.preview_for_quote(quote)
    discount_factor = 1 - (quote.discount_percent.to_d / 100)
    lines = quote.active_lines.map do |line|
      { description: line.description, quantity: line.quantity,
        unit_price: line.unit_price, total: (line.total * discount_factor).round(2) }
    end
    lines << { description: "Transporte", quantity: 1, unit_price: quote.shipping_cost, total: quote.shipping_cost } if quote.shipping_cost.to_d.positive?
    { number: CompanySetting.current.preview_number(QUOTE), provisional: true, issued_on: Date.current,
      client_name: quote.client.name, client_tax_id: quote.client.tax_id.presence, client_address: quote.client.address,
      lines: lines, vat_lines: quote_vat_lines(quote),
      subtotal: quote.subtotal, vat_amount: quote.vat_amount, total: quote.total }
  end

  # Bases por tipo de IVA (para VeriFactu): [{ rate:, base: }].
  def iva_breakdown
    vat_lines.map { |line| { rate: line["rate"].to_d, base: line["base"].to_d } }
  end

  # Bases por tipo del pedido web: líneas agrupadas por el IVA de su producto
  # (0 si la venta está exenta) más el transporte al tipo general.
  def self.order_vat_lines(order)
    return [ { rate: 0.0, base: order.total.to_f } ] if order.vat_exempt?

    bases = Hash.new(0.to_d)
    order.order_lines.each do |line|
      rate = line.product.vat_percentage.to_d
      gross = line.unit_price * line.quantity
      bases[rate] += gross / (1 + rate / 100)
    end
    bases[21.to_d] += order.shipping_cost.to_d / Order::SHIPPING_VAT_FACTOR if order.shipping_cost.to_d.positive?
    bases.map { |rate, base| { rate: rate.to_f, base: base.round(2).to_f } }
  end

  # Bases por tipo del presupuesto: líneas (con el descuento global prorrateado)
  # más el transporte al tipo general del presupuesto.
  def self.quote_vat_lines(quote)
    discount_factor = 1 - (quote.discount_percent.to_d / 100)
    bases = Hash.new(0.to_d)
    quote.active_lines.each do |line|
      bases[line.vat_rate.to_d] += line.total * discount_factor
    end
    bases[quote.vat_rate.to_d] += quote.shipping_cost.to_d if quote.shipping_cost.to_d.positive?
    bases.map { |rate, base| { rate: rate.to_f, base: base.round(2).to_f } }
  end

  private

  def enqueue_verifactu_submission
    return unless CompanySetting.current.verifactu_enabled?

    update_column(:verifactu_status, "pending")
    Verifactu::SubmitInvoiceJob.perform_later(self)
  end
end
