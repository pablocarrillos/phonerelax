require "test_helper"

# Botón «Enviar aviso de envío» del presupuesto APROBADO: manda al almacén (Ana
# y Ginés, copia a Juan Pedro) la dirección, los artículos y la etiqueta A5.
# Exige nombre, dirección y teléfono del cliente; si falta alguno, no envía.
class AdminQuoteShippingEmailTest < ActionDispatch::IntegrationTest
  include QuoteTestHelper

  setup { sign_in_as(users(:one)) }

  def approved_quote(with_shipping: true)
    client = Client.create!(name: "Colegio #{SecureRandom.hex(3)}", phone: with_shipping ? "965000000" : nil)
    create_quote(client: client, status: :aprobado, issued_on: Date.current, delivery_terms: "5 días",
                 vat_rate: 21, contact_phone: with_shipping ? "600111222" : nil,
                 delivery_address: with_shipping ? "C/ Mayor 1\n03600 Elda (Alicante)" : nil,
                 quote_lines_attributes: { "0" => { product_id: products(:funda).id, quantity: 3 } })
  end

  test "el presupuesto aprobado muestra el botón; el abierto no" do
    quote = approved_quote
    get admin_quote_path(quote)
    assert_response :success
    assert_select "form[action=?]", shipping_email_admin_quote_path(quote)

    quote.update!(status: :abierto)
    get admin_quote_path(quote)
    assert_select "form[action=?]", shipping_email_admin_quote_path(quote), count: 0
  end

  test "con nombre, dirección y teléfono encola el email con la etiqueta y deja constancia" do
    quote = approved_quote

    assert_enqueued_emails 1 do
      post shipping_email_admin_quote_path(quote)
    end
    assert_redirected_to admin_quote_path(quote)
    assert_equal 1, quote.quote_events.where(event: "aviso de envío al almacén").count,
                 "queda en el histórico del presupuesto"

    follow_redirect!
    assert_match "ana@servipau.com", flash[:notice]
    assert_match "Último aviso enviado", response.body
  end

  test "si faltan datos del cliente, avisa al pulsar y NO envía" do
    quote = approved_quote(with_shipping: false)

    assert_enqueued_emails 0 do
      post shipping_email_admin_quote_path(quote)
    end
    assert_redirected_to admin_quote_path(quote)
    assert_equal 0, quote.quote_events.where(event: "aviso de envío al almacén").count

    follow_redirect!
    assert_match(/No se puede avisar al almac/i, flash[:alert])
    assert_match(/dirección de envío/i, flash[:alert])
    assert_match(/teléfono/i, flash[:alert])
  end
end
