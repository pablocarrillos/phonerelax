# Envío de facturas en PDF a los clientes desde Contabilidad.
class InvoiceMailer < ApplicationMailer
  # Buzón interno de facturación: recibe una copia de las facturas de ventas web
  # cuando el pedido se marca como enviado. Admite varias cuentas separadas por
  # comas en BILLING_EMAIL.
  BILLING_RECIPIENTS = ENV.fetch("BILLING_EMAIL", "facturacion@drop-point.com")
                          .split(",").map(&:strip)

  def invoice_email(invoice)
    @invoice = invoice
    @setting = CompanySetting.current
    # la copia archivada al emitir: el cliente recibe exactamente el documento
    # que se emitió, no una reimpresión con la plantilla de hoy
    attachments["factura-#{invoice.number}.pdf"] = invoice.pdf_bytes
    mail to: invoice.client_email,
         subject: "Factura #{invoice.number} — #{@setting.legal_name}"
  end

  # Copia de la factura de una venta web para el buzón interno de facturación
  # (NO va al cliente). Se dispara al marcar el pedido como enviado.
  def invoice_to_billing(invoice)
    @invoice = invoice
    @setting = CompanySetting.current
    attachments["factura-#{invoice.number}.pdf"] = invoice.pdf_bytes
    tipo = invoice.simplified? ? "simplificada " : ""
    mail to: BILLING_RECIPIENTS,
         subject: "[Ventas web] Factura #{tipo}#{invoice.number} — #{invoice.client_name}"
  end
end
