require "test_helper"

# Generador de presupuestos: clientes, escalado de precios y PDF imprimible.
class AdminQuotesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @client = Client.create!(name: "Colegio San Luis", tax_id: "ESN0011465B",
                             address: "C/ Portugalete, 1\nPOZUELO DE ALARCÓN (MADRID)\nESPAÑA")
    # Escalado de la funda: 12,3554 € base y 11,1198 € a partir de 100 uds.
    # el tramo base ya existe por fixture: aquí se le pone el precio de estos tests
    products(:funda).price_tiers.find_by!(min_units: 1).update!(unit_price: BigDecimal("12.3554"))
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
    assert_equal BigDecimal("11.12"), line.unit_price    # tramo de 100+ (escalado a 2 decimales)
    assert_equal BigDecimal("2001.6"), line.total        # 180 × 11,12

    assert_equal BigDecimal("2031.35"), quote.subtotal   # + transporte 29,75
    assert_equal BigDecimal("426.5835"), quote.vat_amount
    assert_equal BigDecimal("2457.9335"), quote.total
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
    assert_equal BigDecimal("49.5"), PriceTier.price_for(products(:iman), 3) # 59,90 / 1,21 a 2 decimales
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
    assert_equal BigDecimal("9.88"), PriceTier.price_for(products(:funda), 600)

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

  def a_quote
    Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                  quote_lines_attributes: { "0" => { description: "P", quantity: 1, unit_price: 10, vat_rate: 21 } })
  end

  test "los comentarios del presupuesto guardan fecha/hora y usuario, y se borran" do
    quote = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                          quote_lines_attributes: { "0" => { description: "P", quantity: 1, unit_price: 10, vat_rate: 21 } })

    post admin_quote_comments_path(quote), params: { quote_comment: { body: "Llamado: firma esta semana." } }
    assert_redirected_to admin_quote_path(quote, anchor: "comentarios")
    comment = quote.comments.recent_first.first
    assert_equal "Llamado: firma esta semana.", comment.body
    assert_equal users(:one), comment.user
    assert_in_delta Time.current.to_i, comment.created_at.to_i, 5

    get admin_quote_path(quote)
    assert_includes response.body, "Llamado: firma esta semana."
    assert_includes response.body, comment.author_name

    # vacío no crea nada
    assert_no_difference -> { quote.comments.count } do
      post admin_quote_comments_path(quote), params: { quote_comment: { body: "   " } }
    end

    assert_difference -> { quote.comments.count }, -1 do
      delete admin_quote_comment_path(quote, comment)
    end
  end

  test "el contacto se guarda y el buscador encuentra por textos, contacto, cliente y ficheros" do
    quote = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                          contact_name: "María López", contact_email: "maria@colegiosanluis.es",
                          contact_phone: "612 345 678", delivery_address: "Colegio San Luis, C/ Mayor 1, 03001 Alicante",
                          notes: "pendiente de vinilo dorado",
                          quote_lines_attributes: { "0" => { description: "Funda persianilla bordada", quantity: 1, unit_price: 10, vat_rate: 21 } })
    quote.update!(status: :aprobado)
    patch upload_files_admin_quote_path(quote), params: { quote: { signed_quote: fixture_file_upload("factura.pdf", "application/pdf") } }
    assert quote.reload.signed_quote.attached?

    get admin_quote_path(quote)
    assert_includes response.body, "María López"
    assert_includes response.body, "maria@colegiosanluis.es"
    assert_includes response.body, "612 345 678"
    assert_includes response.body, "Colegio San Luis, C/ Mayor 1, 03001 Alicante"

    # un presupuesto de otro año, para comprobar que la búsqueda abarca todos
    old = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                        quote_lines_attributes: { "0" => { description: "Cinta separadora", quantity: 1, unit_price: 5, vat_rate: 21 } })
    old.update_columns(created_at: 2.years.ago)

    { "maria@colegiosanluis" => quote, "vinilo dorado" => quote, "persianilla" => quote,
      "612 345 678" => quote, "colegio san luis, c/ mayor" => quote,
      "factura.pdf" => quote, "cinta separadora" => old }.each do |term, expected|
      get admin_quotes_path(q: term)
      assert_response :success
      assert_includes response.body, expected.number, "«#{term}» debe encontrar #{expected.number}"
    end

    get admin_quotes_path(q: "no-existe-esto")
    assert_not_includes response.body, quote.number
  end

  test "marcar el estado del presupuesto (aprobado / entregado / en pausa / perdido)" do
    quote = a_quote
    assert quote.abierto?, "por defecto abierto"
    # Sin aprobar no se ofrecen los pasos posteriores (enviado / entregado).
    get admin_quote_path(quote)
    assert_not_includes response.body, "📨 Enviado"
    assert_not_includes response.body, "📦 Entregado"

    patch set_status_admin_quote_path(quote), params: { status: "aprobado" }
    assert quote.reload.aprobado?

    # Aprobado: aparecen «Enviado» y «Entregado». El confirm de «Enviado»
    # recuerda descontar los imanes de muestra que el cliente aún tiene.
    sample = Sample.create!(organization: "Colegio San Luis", quote: quote)
    sample.sample_lines.create!(product: products(:funda), quantity: 2)
    get admin_quote_path(quote)
    assert_includes response.body, "📨 Enviado"
    assert_includes response.body, "📦 Entregado"
    assert_includes response.body, "Recuerda descontar del envío los imanes de muestra enviados"
    assert_includes response.body, "2× #{products(:funda).display_name}"

    # Enviado (tras la aprobación): sigue siendo pedido en firme (cobro y
    # ficheros disponibles).
    patch set_status_admin_quote_path(quote), params: { status: "enviado" }
    assert quote.reload.enviado?
    assert quote.confirmed?
    patch upload_files_admin_quote_path(quote), params: { quote: { signed_quote: fixture_file_upload("factura.pdf", "application/pdf") } }
    assert quote.reload.signed_quote.attached?, "enviado admite ficheros (p. ej. el presupuesto firmado)"

    patch set_status_admin_quote_path(quote), params: { status: "en_pausa" }
    assert quote.reload.en_pausa?
    # Sin aprobar no se ofrece marcar «Entregado».
    get admin_quote_path(quote)
    assert_not_includes response.body, "📦 Entregado"
    patch set_status_admin_quote_path(quote), params: { status: "invento" } # inválido: no cambia
    assert quote.reload.en_pausa?
  end

  test "el filtro por estado suma el total conjunto de los presupuestos" do
    a_quote # abierto: fuera del filtro
    q1 = a_quote
    q2 = a_quote
    q1.update!(status: :aprobado)
    q2.update!(status: :aprobado)

    get admin_quotes_path(status: "aprobado")
    assert_includes response.body, "Totales «Aprobado» (2)"      # pie
    assert_includes response.body, "Totales «Aprobado» · 2 presupuestos" # cabecera
    assert_includes response.body, "20.00" # 2 × 10 € sin IVA
    assert_includes response.body, "24.20" # 2 × 12,10 € con IVA

    # Desglose de las líneas de venta agrupadas: 2 líneas «P» de 1 ud. × 10 €.
    assert_includes response.body, "Líneas de venta («Aprobado»)"
    assert_select "table" do
      assert_select "td", text: "P"
      assert_select "td", text: "2"
    end
    assert_includes response.body, "Total líneas"

    # En los aprobados sale también el plazo de entrega de cada presupuesto.
    assert_includes response.body, "Plazo de entrega"
    assert_select "td", text: "x" # el delivery_terms de a_quote

    get admin_quotes_path
    assert_not_includes response.body, "Total «" # sin filtro no hay fila de totales
    assert_not_includes response.body, "Líneas de venta («"
    assert_not_includes response.body, "Plazo de entrega" # la columna es solo del filtro «Aprobado»
  end

  test "el transporte fijado a mano se conserva al editar y al duplicar" do
    post admin_quotes_path, params: { quote: {
      client_id: @client.id, issued_on: "2026-08-06", delivery_terms: "septiembre", vat_rate: "21",
      shipping_cost: "45.00", manual_shipping: "true",
      quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 1, unit_price: "10" } }
    } }
    quote = Quote.last
    assert quote.manual_shipping?
    assert_equal BigDecimal("45"), quote.shipping_cost

    # Editar otra cosa no toca ni el transporte ni el marcado.
    patch admin_quote_path(quote), params: { quote: { client_id: @client.id, issued_on: "2026-08-06", notes: "otra cosa" } }
    quote.reload
    assert quote.manual_shipping?
    assert_equal BigDecimal("45"), quote.shipping_cost

    # El formulario de edición lleva el flag para que el JS lo respete.
    get edit_admin_quote_path(quote)
    assert_select "input[name='quote[manual_shipping]'][value=?]", "true"

    post duplicate_admin_quote_path(quote)
    assert Quote.last.manual_shipping?, "el duplicado hereda el transporte fijado"
  end

  test "filtrar los presupuestos por estado" do
    a_quote
    approved = a_quote
    approved.update!(status: :aprobado)

    get admin_quotes_path(status: "aprobado")
    assert_select "table:first-of-type tbody tr", 1 # solo la tabla de presupuestos (el desglose de líneas va aparte)
    assert_includes response.body, approved.number

    get admin_quotes_path(status: "invento") # inválido: se ignora y se ven todos
    assert_select "tbody tr", 2
    assert_includes response.body, "Aprobado (1)" # contadores de los chips
    assert_includes response.body, "Abierto (1)"
  end

  test "marcar el cobro (pagado para confirmar / pagado totalmente)" do
    quote = a_quote
    assert quote.sin_pagos?, "por defecto sin pagos"
    patch set_payment_admin_quote_path(quote), params: { payment_status: "pagado_confirmar" }
    assert quote.reload.pagado_confirmar?
    patch set_payment_admin_quote_path(quote), params: { payment_status: "pagado_total" }
    assert quote.reload.pagado_total?
    patch set_payment_admin_quote_path(quote), params: { payment_status: "invento" } # inválido: no cambia
    assert quote.reload.pagado_total?
  end

  test "los ficheros del pedido solo se pueden subir con el presupuesto aprobado" do
    # Con línea de Personalización DTF, para que el fichero «Logo» esté disponible.
    dtf = Product.create!(name: "Personalización DTF test", price: 5, stock: 0, vat_percentage: 21)
    quote = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                          quote_lines_attributes: { "0" => { product_id: dtf.id, quantity: 1 } })
    patch upload_files_admin_quote_path(quote), params: { quote: { school_logo: fixture_file_upload("cover.png", "image/png") } }
    assert_not quote.reload.school_logo.attached?, "abierto: no se admite la subida"

    quote.update!(status: :aprobado)
    patch upload_files_admin_quote_path(quote), params: { quote: {
      school_logo: fixture_file_upload("cover.png", "image/png"),
      signed_quote: fixture_file_upload("factura.pdf", "application/pdf")
    } }
    quote.reload
    assert quote.school_logo.attached?
    assert quote.signed_quote.attached?
    assert_not quote.dtf_file.attached?

    get admin_quote_path(quote)
    assert_includes response.body, "cover.png"
    assert_includes response.body, "factura.pdf"
    assert_select "a.btn", { text: "Ver", count: 2 }, "botón Ver para la imagen y el PDF"

    delete purge_file_admin_quote_path(quote, attachment: "school_logo")
    assert_not quote.reload.school_logo.attached?
    delete purge_file_admin_quote_path(quote, attachment: "invento") # inválido: no borra nada
    assert quote.reload.signed_quote.attached?
  end

  test "la imagen de muestra aprobada solo aplica con personalización DTF" do
    plain = a_quote
    plain.update!(status: :aprobado)
    get admin_quote_path(plain)
    assert_not_includes response.body, "Imagen de muestra aprobada"
    patch upload_files_admin_quote_path(plain), params: { quote: { approved_sample: fixture_file_upload("cover.png", "image/png") } }
    assert_not plain.reload.approved_sample.attached?, "sin DTF no se admite la muestra"

    dtf = Product.create!(name: "Personalización DTF funda", price: 3)
    quote = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, status: :aprobado,
                          quote_lines_attributes: { "0" => { product_id: dtf.id, description: "DTF", quantity: 10, unit_price: 3 } })
    assert quote.dtf_lines?
    get admin_quote_path(quote)
    assert_includes response.body, "Imagen de muestra aprobada"
    patch upload_files_admin_quote_path(quote), params: { quote: { approved_sample: fixture_file_upload("cover.png", "image/png") } }
    assert quote.reload.approved_sample.attached?

    # La miniatura y el enlace de descarga salen en la ficha.
    get admin_quote_path(quote)
    assert_includes response.body, "cover.png"
  end

  test "vincular una muestra enviada a un presupuesto" do
    quote = a_quote
    post admin_samples_path, params: { sample: { organization: "Colegio X", sent_on: "2026-08-05", quote_id: quote.id } }
    assert_equal quote, Sample.last.quote
    assert_equal 1, quote.reload.samples.count
  end

  test "el fichero «Logo» solo está disponible si el presupuesto contrata Personalización DTF" do
    dtf = Product.create!(name: "Personalización DTF test", price: 5, stock: 0, vat_percentage: 21)
    plain = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                          quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 1, unit_price: 10 } })
    assert_not_includes plain.available_files, "school_logo", "sin DTF no aparece el Logo"
    assert_includes plain.available_files, "signed_quote", "el presupuesto firmado siempre está disponible"

    with_dtf = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                             quote_lines_attributes: { "0" => { product_id: dtf.id, quantity: 1 } })
    assert_includes with_dtf.available_files, "school_logo", "con DTF sí aparece el Logo"
  end

  test "el listado de aprobados señala la personalización DTF y su fichero" do
    dtf = Product.create!(name: "Personalización DTF test", price: 5, stock: 0, vat_percentage: 21)
    con_dtf = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                            quote_lines_attributes: { "0" => { product_id: dtf.id, quantity: 25 } })
    con_dtf.update!(status: :aprobado)
    sin_dtf = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                            quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 1, unit_price: "10" } })
    sin_dtf.update!(status: :aprobado)

    # Con líneas DTF y sin fichero subido: la insignia avisa de que falta.
    get admin_quotes_path(status: "aprobado")
    assert_select "th", "DTF"
    assert_includes response.body, "Sin fichero"

    con_dtf.dtf_file.attach(io: File.open(file_fixture("cover.png")), filename: "logo.png", content_type: "image/png")
    get admin_quotes_path(status: "aprobado")
    assert_includes response.body, "Fichero ✓"
    assert_not_includes response.body, "Sin fichero"

    # Fuera del filtro de aprobados la columna no aparece.
    get admin_quotes_path
    assert_select "th", { text: "DTF", count: 0 }
  end

  # El listado arranca en el año en curso (lo habitual al abrirlo) y se puede
  # ampliar a todos los años; los totales de las columnas van arriba del todo.
  test "por defecto solo se ven los presupuestos del año en curso" do
    actual = a_quote
    viejo = a_quote
    viejo.update_columns(created_at: 2.years.ago, issued_on: 2.years.ago.to_date)

    get admin_quotes_path
    assert_response :success
    assert_includes response.body, actual.number
    assert_not_includes response.body, viejo.number
    assert_includes response.body, "Mostrando el año en curso (#{Date.current.year})"

    get admin_quotes_path(all_dates: 1)
    assert_includes response.body, viejo.number
    assert_includes response.body, "Mostrando todos los años"

    # un rango explícito manda sobre el año en curso
    get admin_quotes_path(from: 3.years.ago.to_date.to_s, to: 1.year.ago.to_date.to_s)
    assert_includes response.body, viejo.number
    assert_not_includes response.body, actual.number
  end

  test "la cabecera de la tabla lleva los totales de las columnas" do
    a_quote
    a_quote

    get admin_quotes_path
    assert_response :success
    assert_select "thead tr.total-row" do
      assert_select "th", text: /Totales · 2 presupuestos/
      assert_select "th.num", text: /20[.,]00/
      assert_select "th.num", text: /24[.,]20/
    end
  end


  # Margen estimado: base de venta SIN transporte menos el coste real del
  # pedido (compras imputadas + productos servidos de stock).
  test "el margen descuenta el coste de los productos y deja fuera el transporte" do
    producto = products(:funda)
    proveedor = Supplier.create!(name: "Proveedor margen")
    compra = Purchase.create!(supplier: proveedor, ordered_on: Date.current, currency: "EUR", received_on: Date.current)
    # 100 uds a 2 € + 100 € de transporte → coste real 3 €/ud
    compra.purchase_lines.create!(product: producto, quantity: 100, unit_cost: 2, shipping_cost: 100)

    quote = Quote.create!(client: @client, issued_on: Date.current, shipping_cost: 50, vat_rate: 21, delivery_terms: "x",
                          quote_lines_attributes: { "0" => { product_id: producto.id, description: "Fundas",
                                                             quantity: 10, unit_price: 10, vat_rate: 21 } })

    assert_equal 100, quote.lines_base.to_f, "10 × 10 € (el transporte no entra)"
    assert_equal 150, quote.subtotal.to_f, "el subtotal del presupuesto sí lo incluye"
    assert_equal 30, quote.product_cost_eur.to_f, "10 uds × 3 € de coste real"
    assert_equal 70, quote.estimated_margin_eur.to_f, "100 − 30"
    assert_equal 70.0, quote.estimated_margin_percent.to_f

    get admin_quote_path(quote)
    assert_response :success
    body = response.body.dup.force_encoding("UTF-8")
    assert_includes body, "Margen estimado"
    assert_match(/70[.,]00\s*€/, body)
    assert_match(/70[.,]0\s*%/, body)
    assert_includes body, "El <strong>transporte</strong>"
  end

  test "una compra imputada no cuenta dos veces el mismo producto" do
    producto = products(:funda)
    proveedor = Supplier.create!(name: "Proveedor imputado")
    recibida = Purchase.create!(supplier: proveedor, ordered_on: Date.current, currency: "EUR", received_on: Date.current)
    recibida.purchase_lines.create!(product: producto, quantity: 100, unit_cost: 2, shipping_cost: 100) # 3 €/ud

    quote = Quote.create!(client: @client, issued_on: Date.current, shipping_cost: 0, vat_rate: 21, delivery_terms: "x",
                          quote_lines_attributes: { "0" => { product_id: producto.id, description: "Fundas",
                                                             quantity: 10, unit_price: 10, vat_rate: 21 } })

    # se compran 6 uds expresamente para este presupuesto, a 4 € reales
    imputada = Purchase.create!(supplier: proveedor, ordered_on: Date.current, currency: "EUR", received_on: Date.current)
    imputada.purchase_lines.create!(product: producto, quantity: 6, unit_cost: 4, quote: quote)

    quote.reload
    assert_equal 24.0, quote.imputed_cost_eur.to_f, "6 × 4 €"
    # solo se valoran las 4 uds que NO cubre la compra imputada; el coste medio
    # es el de todas las compras recibidas del producto (3 € y 4 €)
    assert_in_delta 12.23, quote.product_cost_eur.to_f, 0.01
    assert_in_delta 63.77, quote.estimated_margin_eur.to_f, 0.01, "100 − 24 − coste de las 4 restantes"
  end

  test "sin costes conocidos no se inventa margen" do
    quote = Quote.create!(client: @client, issued_on: Date.current, shipping_cost: 0, vat_rate: 21, delivery_terms: "x",
                          quote_lines_attributes: { "0" => { description: "Servicio a medida", quantity: 1,
                                                             unit_price: 500, vat_rate: 21 } })
    assert_equal 0, quote.product_cost_eur.to_f
    get admin_quote_path(quote)
    assert_not_includes response.body, "Margen estimado"
  end
end
