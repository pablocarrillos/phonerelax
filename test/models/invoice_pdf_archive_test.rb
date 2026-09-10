require "test_helper"

# Copia en PDF de cada factura emitida: cuándo se archiva, que no se reescribe
# nunca, y que a partir de entonces es lo que se sirve y lo que se adjunta.
class InvoicePdfArchiveTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # cliente de VeriFactu de mentira: devuelve el resultado que le den
  class FakeClient
    def initialize(result) = @result = result
    def submit(_payload) = @result
  end

  setup do
    @setting = CompanySetting.current
    @setting.update!(verifactu_enabled: false)
    @product = Product.create!(name: "Bolsa copia", price: 12.10, stock: 100, vat_percentage: 21, active: true)
    @order = Order.create!(customer_name: "Ana Copia", email: "ana@example.com", phone: "612345678",
                           address: "C 1", city: "Elda", postal_code: "03600", province: "Alicante",
                           country: "España", payment_status: :pagado, total: 24.90, shipping_cost: 0.70)
    @order.order_lines.create!(product: @product, quantity: 2, unit_price: 12.10)
  end

  # --- cuándo se archiva ---

  test "sin VeriFactu la copia se archiva al emitir la factura" do
    invoice = Invoice.issue_for_order!(@order)

    assert invoice.reload.pdf_archive.attached?
    assert_equal "factura-#{invoice.number}.pdf", invoice.pdf_archive.filename.to_s
    assert_equal "application/pdf", invoice.pdf_archive.content_type
    assert invoice.pdf_archive.download.start_with?("%PDF")
  end

  test "con VeriFactu no se archiva al emitir: se espera al envío, que es quien pone el QR" do
    @setting.update!(verifactu_enabled: true, verifactu_token: "tok", tax_id: "B02631976")
    invoice = Invoice.issue_for_order!(@order)

    assert_equal "pending", invoice.reload.verifactu_status
    assert_not invoice.pdf_archive.attached?, "una factura sin QR todavía no es el documento definitivo"
    assert_empty Invoice.pending_pdf_archive.where(id: invoice.id)
  end

  test "el envío correcto a VeriFactu archiva la copia" do
    @setting.update!(verifactu_enabled: true, verifactu_token: "tok", tax_id: "B02631976")
    invoice = Invoice.issue_for_order!(@order)
    result = Verifactu::Result.new(ok: true, huella: "H1", qr: nil, url: "https://aeat.example/x")

    with_verifactu_client(FakeClient.new(result)) do
      Verifactu::SubmitInvoiceJob.perform_now(invoice)
    end

    assert_equal "sent", invoice.reload.verifactu_status
    assert invoice.pdf_archive.attached?
  end

  # --- que no se reescriba ---

  test "archivar es idempotente: la copia no se regenera ni se sustituye" do
    invoice = Invoice.issue_for_order!(@order)
    original = invoice.reload.pdf_archive.download

    assert_not invoice.archive_pdf!, "no debe volver a archivar"
    assert_equal original, invoice.reload.pdf_archive.download
  end

  test "la copia archivada no cambia aunque cambien los datos de la empresa" do
    invoice = Invoice.issue_for_order!(@order)
    archived = invoice.reload.pdf_bytes

    assert_equal archived, invoice.to_pdf, "de partida, reimprimir da exactamente la copia guardada"

    @setting.update!(legal_name: "Otro Nombre S.L.")
    invoice = Invoice.find(invoice.id)

    assert_not_equal archived, invoice.to_pdf, "una reimpresión de hoy ya no es el documento que se emitió"
    assert_equal archived, invoice.pdf_bytes, "y aun así se sirve la copia archivada"
  end

  test "el correo al cliente lleva adjunta la copia archivada, no una reimpresión" do
    invoice = Invoice.issue_for_order!(@order)
    archived = invoice.reload.pdf_archive.download
    @setting.update!(legal_name: "Otro Nombre S.L.")

    mail = InvoiceMailer.invoice_email(Invoice.find(invoice.id))
    adjunto = mail.attachments["factura-#{invoice.number}.pdf"]

    assert_equal archived, adjunto.body.decoded
  end

  # --- repaso de las que falten ---

  # Sustituye Verifactu::Client.new durante el bloque (minitest 6 ya no trae
  # minitest/mock; mismo apaño que en purchase_flow_test).
  def with_verifactu_client(fake)
    singleton = Verifactu::Client.singleton_class
    original = Verifactu::Client.method(:new)
    singleton.define_method(:new) { |*_args, **_kwargs| fake }
    yield
  ensure
    singleton.define_method(:new, original)
  end

  test "el repaso archiva las que faltan y no toca las pendientes de VeriFactu" do
    lista = Invoice.issue_for_order!(@order)
    lista.pdf_archive.purge
    pendiente = Invoice.issue_rectification!(lista)
    pendiente.pdf_archive.purge if pendiente.pdf_archive.attached?
    pendiente.update_column(:verifactu_status, "pending")

    assert_equal [ lista ], Invoice.pending_pdf_archive.to_a

    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["invoices:archive_pdfs"].reenable
    capture_io { Rake::Task["invoices:archive_pdfs"].invoke }

    assert lista.reload.pdf_archive.attached?
    assert_not pendiente.reload.pdf_archive.attached?
  end
end
