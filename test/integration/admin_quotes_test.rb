require "test_helper"

# Generador de presupuestos: clientes, escalado de precios y PDF imprimible.
class AdminQuotesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @client = Client.create!(name: "Colegio San Luis", tax_id: "ESN0011465B",
                             address: "C/ Portugalete, 1\nPOZUELO DE ALARCÓN (MADRID)\nESPAÑA")
    # Escalado de la funda: 12,3554 € base y 11,1198 € a partir de 100 uds.
    products(:funda).price_tiers.create!(min_units: 1, unit_price: BigDecimal("12.3554"))
    products(:funda).price_tiers.create!(min_units: 100, unit_price: BigDecimal("11.1198"))
    # El test de compra en tienda pasa por el checkout público, con antibots.
    @timestamp_was = InvisibleCaptcha.timestamp_enabled
    @spinner_was = InvisibleCaptcha.spinner_enabled
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false
  end

  teardown do
    InvisibleCaptcha.timestamp_enabled = @timestamp_was
    InvisibleCaptcha.spinner_enabled = @spinner_was
  end

  test "alta de clientes con datos fiscales" do
    post admin_clients_path, params: { client: { name: "Ayto. Peñíscola", tax_id: "P1208900E" } }
    assert_redirected_to admin_clients_path
    get admin_clients_path
    assert_response :success
    assert_includes response.body, "Ayto. Peñíscola"
  end

  test "el presupuesto aplica el escalado según unidades y calcula los totales" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", shipping_cost: "29.75", vat_rate: "21",
      quote_lines_attributes: {
        "0" => { product_id: products(:funda).id, quantity: 180, description: "", unit_price: "" },
        "1" => { product_id: "", description: "", quantity: "", unit_price: "" }
      }
    } }
    quote = Quote.last
    assert_redirected_to admin_quote_path(quote)
    assert_match(/\APR\d{4}-\d{4}\z/, quote.number)

    line = quote.quote_lines.sole
    assert_equal products(:funda).name, line.description # descripción autocompletada
    assert_equal BigDecimal("11.1198"), line.unit_price  # tramo de 100+
    assert_equal BigDecimal("2001.56"), line.total       # 180 × 11,1198 redondeado

    assert_equal BigDecimal("2031.31"), quote.subtotal   # + transporte 29,75
    assert_equal BigDecimal("426.5751"), quote.vat_amount
    assert_equal BigDecimal("2457.8851"), quote.total
  end

  test "los campos autocompletados se pueden fijar a mano" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", shipping_cost: "0",
      quote_lines_attributes: { "0" => { product_id: products(:funda).id, quantity: 180,
                                         description: "Bolsa SignalBlocking con tarjetero",
                                         unit_price: "11.97" } }
    } }
    line = Quote.last.quote_lines.sole
    assert_equal "Bolsa SignalBlocking con tarjetero", line.description
    assert_equal BigDecimal("11.97"), line.unit_price
  end

  test "sin escalado, el precio cae al PVP sin IVA" do
    assert_equal BigDecimal("49.5041"), PriceTier.price_for(products(:iman), 3).round(4) # 59,90 / 1,21
  end

  test "la versión imprimible muestra el formato oficial con cuenta y observaciones" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", shipping_cost: "29.75",
      payment_terms: "Pago a 30 días.", delivery_terms: "1 de septiembre de 2026",
      bank_account: Quote::BANK_ACCOUNTS.last, remarks: "Incluye 2 imanes de repuesto sin coste.",
      quote_lines_attributes: { "0" => { product_id: products(:funda).id, quantity: 180 } }
    } }
    quote = Quote.last
    get print_admin_quote_path(quote)
    assert_response :success
    assert_includes response.body, "Drop Point Systems S.L.U."
    assert_includes response.body, quote.number
    assert_includes response.body, "Colegio San Luis"
    assert_includes response.body, "Total Oferta"
    assert_includes response.body, "BBVA ES65 0182 2961 3102 0170 2952"
    assert_includes response.body, "Incluye 2 imanes de repuesto"
    assert_includes response.body, "EN EL ASUNTO DE LA TRANSFERENCIA"
  end

  test "duplicar un presupuesto crea uno nuevo con número y fechas nuevos" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-07-01", valid_until: "2026-07-08", shipping_cost: "29.75",
      remarks: "Observación heredada",
      quote_lines_attributes: { "0" => { product_id: products(:funda).id, quantity: 180 } }
    } }
    original = Quote.last
    assert_difference "Quote.count", 1 do
      post duplicate_admin_quote_path(original)
    end
    copy = Quote.last
    assert_redirected_to edit_admin_quote_path(copy)
    assert_not_equal original.number, copy.number
    assert_equal Date.current, copy.issued_on
    assert_equal original.quote_lines.first.unit_price, copy.quote_lines.first.unit_price
    assert_equal "Observación heredada", copy.remarks
  end

  test "sin cuenta elegida se imprime la histórica de CAJAMAR" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", shipping_cost: "0",
      quote_lines_attributes: { "0" => { product_id: products(:funda).id, quantity: 1 } }
    } }
    get print_admin_quote_path(Quote.last)
    assert_includes response.body, "CAJAMAR ES41 3029 7241 2527 2000 9053"
  end

  test "el escalado se gestiona desde la ficha del producto (añadir, editar y quitar tramos)" do
    tier = products(:funda).price_tiers.find_by(min_units: 100)
    patch admin_product_path(products(:funda)), params: { product: {
      name: products(:funda).name, price: products(:funda).price,
      price_tiers_attributes: {
        "0" => { id: tier.id, min_units: 100, unit_price: "11.00" },
        "1" => { min_units: 500, unit_price: "9.8843" },
        "2" => { min_units: "", unit_price: "" } # hueco vacío: se ignora
      }
    } }
    assert_redirected_to admin_products_path
    assert_equal BigDecimal("11"), tier.reload.unit_price
    assert_equal BigDecimal("9.8843"), PriceTier.price_for(products(:funda), 600)

    patch admin_product_path(products(:funda)), params: { product: {
      name: products(:funda).name, price: products(:funda).price,
      price_tiers_attributes: { "0" => { id: tier.id, _destroy: "1" } }
    } }
    assert_nil PriceTier.find_by(id: tier.id)
  end

  test "el escalado se aplica también comprando en la tienda" do
    # 25+ uds. a 10,00 € sin IVA → 12,10 € con IVA en el carrito y el pedido.
    products(:funda).update!(stock: 100)
    products(:funda).price_tiers.create!(min_units: 25, unit_price: BigDecimal("10"))
    assert_equal BigDecimal("12.1"), products(:funda).price_for_quantity(25)
    assert_equal products(:iman).price, products(:iman).price_for_quantity(3) # producto sin escalado

    post cart_add_path(product_id: products(:funda)), params: { quantity: 25 }
    get cart_path
    assert_response :success
    assert_includes response.body, "302.50" # 25 × 12,10

    post orders_path, params: { order: { customer_name: "Ana", email: "a@x.com", phone: "612345678",
                                         address: "C 1", city: "Madrid", postal_code: "28001",
                                         province: "Madrid", country: "España" } }
    order = Order.last
    assert_equal BigDecimal("12.1"), order.order_lines.sole.unit_price
  end
end
