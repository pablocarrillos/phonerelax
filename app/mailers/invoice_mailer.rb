# Envío de facturas en PDF a los clientes desde Contabilidad.
class InvoiceMailer < ApplicationMailer
  def invoice_email(invoice)
    @invoice = invoice
    @setting = CompanySetting.current
    # la copia archivada al emitir: el cliente recibe exactamente el documento
    # que se emitió, no una reimpresión con la plantilla de hoy
    attachments["factura-#{invoice.number}.pdf"] = invoice.pdf_bytes
    mail to: invoice.client_email,
         subject: "Factura #{invoice.number} — #{@setting.legal_name}"
  end
end
