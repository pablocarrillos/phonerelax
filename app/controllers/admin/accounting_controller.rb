# "Contabilidad": facturación de un tramo de fechas — ventas web pagadas y
# presupuestos aprobados. Por cada uno: previsualizar el PDF, generar la factura
# (con VeriFactu si está activo) y enviarla por email; o todo de golpe.
module Admin
  class AccountingController < BaseController
  before_action :load_range

  def index
    @orders = Order.pago_pagado.where(created_at: @from.beginning_of_day..@to.end_of_day)
                   .includes(order_lines: :product).order(created_at: :desc)
    @quotes = Quote.where(status: %w[aprobado entregado], issued_on: @from..@to)
                   .includes(:client).order(issued_on: :desc)
    @invoices_by_order = Invoice.where(order_id: @orders.map(&:id)).index_by(&:order_id)
    @invoices_by_quote = Invoice.where(quote_id: @quotes.map(&:id)).index_by(&:quote_id)
  end

  # PDF de previsualización (sin guardar) o de la factura ya emitida.
  def preview
    data = if params[:order_id]
             order = Order.find(params[:order_id])
             Invoice.find_by(order: order)&.pdf_data || Invoice.preview_for_order(order)
    else
             quote = Quote.find(params[:quote_id])
             Invoice.find_by(quote: quote)&.pdf_data || Invoice.preview_for_quote(quote)
    end
    send_data InvoicePdf.render(data), filename: "factura-#{data[:number]}.pdf",
                                       type: "application/pdf", disposition: "inline"
  end

  # Genera la factura de un pedido o presupuesto concreto.
  def generate
    invoice = generate_one
    redirect_to range_path, notice: "Factura #{invoice.number} generada."
  rescue ArgumentError => e
    redirect_to range_path, alert: e.message
  end

  # Envía por email (con el PDF) una factura ya generada.
  def send_email
    invoice = Invoice.find(params[:invoice_id])
    return redirect_to(range_path, alert: "La factura #{invoice.number} no tiene email de cliente.") if invoice.client_email.blank?

    InvoiceMailer.invoice_email(invoice).deliver_later
    invoice.update!(emailed_at: Time.current)
    redirect_to range_path, notice: "Factura #{invoice.number} enviada a #{invoice.client_email}."
  end

  # Lo gordo: genera TODAS las facturas del tramo elegido y las envía por email
  # a los clientes que tengan dirección. Idempotente: lo ya facturado no se
  # duplica, y lo ya enviado no se reenvía.
  def generate_and_send_all
    generated = 0
    sent = 0
    each_billable do |source|
      invoice = source.is_a?(Order) ? Invoice.issue_for_order!(source) : Invoice.issue_for_quote!(source)
      generated += 1 if invoice.previously_new_record?
      next if invoice.client_email.blank? || invoice.emailed_at.present?

      InvoiceMailer.invoice_email(invoice).deliver_later
      invoice.update!(emailed_at: Time.current)
      sent += 1
    rescue ArgumentError
      next
    end
    redirect_to range_path, notice: "#{generated} facturas generadas y #{sent} enviadas para el tramo #{l(@from)} – #{l(@to)}."
  end

  # Reintenta el alta en VeriFactu de una factura con error.
  def resubmit_verifactu
    invoice = Invoice.find(params[:invoice_id])
    invoice.submit_to_verifactu!
    redirect_to range_path, notice: "Factura #{invoice.number} reenviada a VeriFactu."
  end

  private

  def generate_one
    if params[:order_id]
      Invoice.issue_for_order!(Order.find(params[:order_id]))
    else
      Invoice.issue_for_quote!(Quote.find(params[:quote_id]))
    end
  end

  def each_billable(&block)
    Order.pago_pagado.where(created_at: @from.beginning_of_day..@to.end_of_day).find_each(&block)
    Quote.where(status: %w[aprobado entregado], issued_on: @from..@to).find_each(&block)
  end

  def load_range
    @from = (Date.parse(params[:from]) rescue Date.current.beginning_of_month)
    @to = (Date.parse(params[:to]) rescue Date.current)
  end

  def range_path
    admin_accounting_index_path(from: @from, to: @to)
  end
  end
end
