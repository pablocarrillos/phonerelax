require "test_helper"

# Contabilidad: datos de empresa con dos series, facturas de ventas web y de
# presupuestos aprobados, PDF, envío por email y VeriFactu (como gestion/agua).
class AccountingTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    sign_in_as(users(:one))
    @setting = CompanySetting.current
    @product = Product.create!(name: "Bolsa test", price: 12.10, stock: 100, vat_percentage: 21, active: true)
    @order = Order.create!(customer_name: "Ana Test", email: "ana@example.com", phone: "612345678",
                           address: "C 1", city: "Elda", postal_code: "03600", province: "Alicante",
                           country: "España", payment_status: :pagado, total: 24.90, shipping_cost: 0.70)
    @order.order_lines.create!(product: @product, quantity: 2, unit_price: 12.10) # 24,20 + 0,70 = 24,90
    Order.where.not(id: @order.id).update_all(created_at: 2.years.ago) # las fixtures, fuera del tramo

    @client = Client.create!(name: "Colegio Test", tax_id: "B00000000", address: "Calle 1", email: "cole@example.com")
    @quote = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                           quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 10, unit_price: "10", vat_rate: 21 } })
    @quote.update!(status: :aprobado)
  end

  test "los ajustes nacen con los datos de Drop Point Systems y dos series independientes" do
    yy = Date.current.strftime("%y")
    assert_equal "Drop Point Systems S.L.U.", @setting.legal_name
    assert_equal "B02631976", @setting.tax_id
    assert_equal "WEB#{yy}-0001", @setting.take_number!("web")
    assert_equal "PRES#{yy}-0001", @setting.take_number!("quote")
    assert_equal "WEB#{yy}-0002", @setting.take_number!("web"), "las series no se pisan"
  end

  test "al cambiar de año la serie lleva el año nuevo y reinicia en 0001" do
    yy = Date.current.strftime("%y")
    @setting.update!(web_series_year: Date.current.year - 1, web_next_number: 57)

    assert_equal "WEB#{yy}-0001", @setting.preview_number("web")
    assert_equal "WEB#{yy}-0001", @setting.take_number!("web")
    assert_equal "WEB#{yy}-0002", @setting.take_number!("web")
  end

  test "la factura de una venta web copia cliente e importes y desglosa el IVA" do
    invoice = Invoice.issue_for_order!(@order)

    assert_equal "WEB#{Date.current.strftime('%y')}-0001", invoice.number
    assert_equal @order.customer_name, invoice.client_name
    assert_equal 24.90, invoice.total.to_f
    assert_equal [ 21.0 ], invoice.iva_breakdown.map { |b| b[:rate].to_f }
    assert_in_delta 20.58, invoice.iva_breakdown.sum { |b| b[:base].to_f }, 0.02
    assert_equal invoice, Invoice.issue_for_order!(@order), "idempotente"
  end

  test "un pedido sin pagar no se factura" do
    @order.update!(payment_status: :pendiente)
    assert_raises(ArgumentError) { Invoice.issue_for_order!(@order) }
  end

  test "la factura de un presupuesto aprobado usa su serie y sus totales" do
    invoice = Invoice.issue_for_quote!(@quote)

    assert_equal "PRES#{Date.current.strftime('%y')}-0001", invoice.number
    assert_equal "Colegio Test", invoice.client_name
    assert_equal @quote.total.to_f, invoice.total.to_f
    assert_equal invoice, Invoice.issue_for_quote!(@quote), "idempotente"

    abierto = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                            quote_lines_attributes: { "0" => { description: "Otra", quantity: 1, unit_price: "5", vat_rate: 21 } })
    assert_raises(ArgumentError) { Invoice.issue_for_quote!(abierto) }
  end

  test "el payload de VeriFactu agrega por tipo de IVA y marca simplificada sin NIF" do
    invoice = Invoice.issue_for_quote!(@quote)
    payload = Verifactu::InvoicePayload.build(invoice)

    assert_equal "PRES#{Date.current.strftime('%y')}", payload[:serie]
    assert_equal "0001", payload[:numero]
    assert_not payload[:simplificada]
    assert_equal "B00000000", payload[:nif]
    assert_equal 1, payload[:lineas].size
    assert_in_delta 100.0, payload[:lineas].first[:importe_unitario], 0.01

    web = Invoice.issue_for_order!(@order) # sin NIF -> simplificada
    assert Verifactu::InvoicePayload.build(web)[:simplificada]
  end

  test "con VeriFactu activado la emisión encola el envío" do
    @setting.update!(verifactu_enabled: true, verifactu_token: "tok")
    assert_enqueued_with(job: Verifactu::SubmitInvoiceJob) do
      Invoice.issue_for_quote!(@quote)
    end
  end

  test "el PDF se genera para previsualización y para la factura emitida" do
    preview = InvoicePdf.render(Invoice.preview_for_order(@order))
    assert preview.start_with?("%PDF")

    invoice = Invoice.issue_for_quote!(@quote)
    assert InvoicePdf.render(invoice.pdf_data).start_with?("%PDF")
  end

  test "el email de factura lleva el PDF adjunto" do
    invoice = Invoice.issue_for_quote!(@quote)
    mail = InvoiceMailer.invoice_email(invoice)

    assert_equal [ "cole@example.com" ], mail.to
    assert_includes mail.subject, invoice.number
    assert_equal 1, mail.attachments.size
    assert_equal "factura-#{invoice.number}.pdf", mail.attachments.first.filename
  end

  test "el panel lista el tramo y genera y envía todo de golpe" do
    get admin_accounting_index_path(from: Date.current.beginning_of_month, to: Date.current)
    assert_response :success
    assert_includes response.body, @order.number
    assert_includes response.body, @quote.number

    assert_difference -> { Invoice.count }, 2 do
      assert_emails 2 do # pedido web y presupuesto: ambos con email
        perform_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
          post generate_and_send_all_admin_accounting_index_path(from: Date.current.beginning_of_month, to: Date.current)
        end
      end
    end
    assert Invoice.find_by(quote_id: @quote.id).emailed_at.present?

    # idempotente: repetir no duplica ni reenvía
    assert_no_difference -> { Invoice.count } do
      post generate_and_send_all_admin_accounting_index_path(from: Date.current.beginning_of_month, to: Date.current)
    end
  end
end
