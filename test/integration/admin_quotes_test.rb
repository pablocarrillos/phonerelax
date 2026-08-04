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
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "29.75", vat_rate: "21",
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
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "0",
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

  test "la previsualización muestra el PDF del formulario sin guardar nada" do
    assert_no_difference "Quote.count" do
      post admin_quotes_path, params: { preview: "1", quote: {
        client_id: @client.id, issued_on: "2026-08-04", shipping_cost: "29.75",
        quote_lines_attributes: { "0" => { product_id: products(:funda).id, quantity: 180 } }
      } }
    end
    assert_response :success
    assert_includes response.body, "BORRADOR"
    assert_includes response.body, "Colegio San Luis"
    assert_includes response.body, "11.12" # precio del escalado aplicado también en la preview
    assert_includes response.body, "Total Oferta"
  end

  test "la previsualización de un presupuesto existente usa su número real" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "septiembre", shipping_cost: "0",
      quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 1, unit_price: "10" } }
    } }
    quote = Quote.last
    patch admin_quote_path(quote), params: { preview: "1", quote: { client_id: @client.id, issued_on: "2026-08-04" } }
    assert_response :success
    assert_includes response.body, quote.number
    assert_not_includes response.body, "BORRADOR"
  end

  test "la previsualización sin cliente avisa en lugar de fallar" do
    post admin_quotes_path, params: { preview: "1", quote: { issued_on: "2026-08-04" } }
    assert_response :unprocessable_entity
    assert_includes response.body, "Elige un cliente"
  end

  test "descuento por línea y descuento global se aplican a los totales" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "0", vat_rate: "21", discount_percent: "5",
      quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 100, unit_price: "10", vat_rate: "21", discount_percent: "10" } }
    } }
    quote = Quote.last
    assert_equal BigDecimal("900"), quote.quote_lines.sole.total # 1000 − 10 %
    assert_equal BigDecimal("45"), quote.discount_amount          # 5 % de 900
    assert_equal BigDecimal("855"), quote.subtotal
    assert_in_delta 179.55, quote.vat_amount.to_f, 0.01           # 21 % sobre la base con descuentos
    assert_in_delta 1034.55, quote.total.to_f, 0.01
  end

  test "el documento solo muestra los descuentos cuando se usan" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "0",
      quote_lines_attributes: { "0" => { description: "Sin descuento", quantity: 1, unit_price: "10" } }
    } }
    get print_admin_quote_path(Quote.last)
    assert_not_includes response.body, "Dto."
    assert_not_includes response.body, "Descuento"

    Quote.last.update!(discount_percent: 5)
    Quote.last.quote_lines.sole.update!(discount_percent: 10)
    get print_admin_quote_path(Quote.last)
    assert_includes response.body, "Dto."
    assert_includes response.body, "Descuento 5%"
  end

  test "las líneas marcadas con _destroy se eliminan al guardar" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "0",
      quote_lines_attributes: { "0" => { description: "Uno", quantity: 1, unit_price: "10" },
                                "1" => { description: "Dos", quantity: 2, unit_price: "5" } }
    } }
    quote = Quote.last
    doomed = quote.quote_lines.find_by(description: "Dos")
    patch admin_quote_path(quote), params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04",
      quote_lines_attributes: { "0" => { id: doomed.id, _destroy: "1" } }
    } }
    assert_equal [ "Uno" ], quote.reload.quote_lines.pluck(:description)
  end

  test "el transporte calculado usa la config de Transporte y el país de envío" do
    ShippingRate.create!(country: "España", base_cost: BigDecimal("5.95"))
    ShippingRate.create!(country: "Francia", base_cost: BigDecimal("11.50"))
    products(:funda).update!(shipping_unit_cost: BigDecimal("2"))

    quote = Quote.new(client: @client, issued_on: Date.current, vat_rate: 21, shipping_country: "España")
    quote.quote_lines.build(product: products(:funda), description: "Fundas", quantity: 10, unit_price: 10)
    # (5,95 + 10 × 2) / 1,21 = 21,45 sin IVA
    assert_equal BigDecimal("21.45"), quote.computed_shipping

    quote.shipping_country = "Francia"
    assert_equal BigDecimal("26.03"), quote.computed_shipping # (11,50 + 20) / 1,21

    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "21.45", shipping_country: "Francia",
      quote_lines_attributes: { "0" => { product_id: products(:funda).id, quantity: 10 } }
    } }
    assert_equal "Francia", Quote.last.shipping_country
  end

  test "las líneas se ordenan por su posición en todo el documento" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "0",
      quote_lines_attributes: { "0" => { description: "Primera", quantity: 1, unit_price: "10", position: 1 },
                                "1" => { description: "Segunda", quantity: 1, unit_price: "5", position: 2 } }
    } }
    quote = Quote.last
    assert_equal [ "Primera", "Segunda" ], quote.quote_lines.pluck(:description)

    lines = quote.quote_lines.to_a
    patch admin_quote_path(quote), params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04",
      quote_lines_attributes: { "0" => { id: lines[0].id, position: 2 }, "1" => { id: lines[1].id, position: 1 } }
    } }
    assert_equal [ "Segunda", "Primera" ], quote.reload.quote_lines.pluck(:description)
    get print_admin_quote_path(quote)
    assert response.body.index("Segunda") < response.body.index("Primera"), "el PDF respeta el orden"
  end

  test "la descripción interna sale en el listado y se puede filtrar por cliente" do
    otro = Client.create!(name: "Otro Centro")
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "septiembre", shipping_cost: "0",
      internal_description: "180 uds. curso 26/27",
      quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 1, unit_price: "10" } }
    } }
    post admin_quotes_path, params: { quote: {
      client_id: otro.id, issued_on: "2026-08-04", delivery_terms: "septiembre", shipping_cost: "0",
      quote_lines_attributes: { "0" => { description: "Imanes", quantity: 1, unit_price: "40" } }
    } }

    get admin_quotes_path
    assert_includes response.body, "180 uds. curso 26/27"

    get admin_quotes_path(client_id: @client.id)
    assert_includes response.body, "Mostrando solo los presupuestos de"
    assert_includes response.body, @client.name
    assert_select "tbody tr", 1
  end

  test "un presupuesto sin líneas no se puede crear" do
    assert_no_difference "Quote.count" do
      post admin_quotes_path, params: { quote: { client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "29.75" } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "al menos una línea"
  end

  test "duplicar un presupuesto crea uno nuevo con número y fechas nuevos" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-07-01", valid_until: "2026-07-08", shipping_cost: "29.75", delivery_terms: "julio 2026",
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
      client_id: @client.id, issued_on: "2026-08-04", delivery_terms: "1 de septiembre de 2026", shipping_cost: "0",
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

  test "el plazo de entrega es obligatorio y las condiciones por defecto son 50/50" do
    assert_no_difference "Quote.count" do
      post admin_quotes_path, params: { quote: {
        client_id: @client.id, issued_on: "2026-08-04", shipping_cost: "0",
        quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 1, unit_price: "10" } }
      } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Plazo de entrega"

    get new_admin_quote_path
    assert_includes response.body, "50% IVA incluido para confirmar y 50% a la entrega."
  end
end
