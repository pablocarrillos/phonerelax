# Envío de facturas en PDF a los clientes desde Contabilidad.
class InvoiceMailer < ApplicationMailer
  def invoice_email(invoice)
    @invoice = invoice
    @setting = CompanySetting.current
    attachments["factura-#{invoice.number}.pdf"] = InvoicePdf.render(invoice.pdf_data)
    mail to: invoice.client_email,
         subject: "Factura #{invoice.number} — #{@setting.legal_name}"
  end
end
