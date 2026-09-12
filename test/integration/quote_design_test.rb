require "test_helper"

# Diseño de la funda en el presupuesto: las dos imágenes son obligatorias para
# emitirlo, el documento pide firma y sello aprobando ese diseño, y los
# productos con arte (etiqueta con nombre, DTF) obligan a revisarlo con el
# cliente antes de fabricar.
class QuoteDesignTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @client = Client.create!(name: "Colegio del Diseño", tax_id: "B12345678", address: "C/ Mayor 1")
  end

  def quote_params(**extra)
    { client_id: @client.id, issued_on: Date.current.iso8601, delivery_terms: "1 de septiembre",
      shipping_cost: "0", vat_rate: 21,
      quote_lines_attributes: { "0" => { description: "Fundas", quantity: 10, unit_price: "10", vat_rate: 21 } } }
      .merge(extra)
  end

  # --- las dos imágenes son obligatorias ---

  test "sin las dos imágenes del diseño no se puede emitir el presupuesto" do
    assert_no_difference -> { Quote.count } do
      post admin_quotes_path, params: { quote: quote_params }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "Falta la imagen del diseño: parte delantera"
    assert_includes response.body, "Falta la imagen del diseño: parte trasera"
  end

  test "con una sola imagen tampoco: hacen falta las dos caras" do
    solo_delantera = design_image_params.except(:case_back_image)

    assert_no_difference -> { Quote.count } do
      post admin_quotes_path, params: { quote: quote_params(**solo_delantera) }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "parte trasera"
    assert_not_includes response.body, "Falta la imagen del diseño: parte delantera"
  end

  test "con las dos imágenes se emite y quedan guardadas" do
    assert_difference -> { Quote.count }, 1 do
      post admin_quotes_path, params: { quote: quote_params(**design_image_params) }
    end

    quote = Quote.last
    assert_redirected_to admin_quote_path(quote)
    assert quote.case_images?
    assert quote.case_front_image.attached?
    assert quote.case_back_image.attached?
  end

  test "un presupuesto anterior a la norma se sigue pudiendo editar, y su ficha lo avisa" do
    quote = create_quote(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0,
                         quote_lines_attributes: { "0" => { description: "P", quantity: 1, unit_price: 10, vat_rate: 21 } })
    quote.case_front_image.purge
    quote.case_back_image.purge

    patch admin_quote_path(quote), params: { quote: { delivery_terms: "2 semanas" } }
    assert_redirected_to admin_quote_path(quote)
    assert_equal "2 semanas", quote.reload.delivery_terms

    get admin_quote_path(quote)
    assert_includes response.body, "Faltan imágenes del diseño"
  end

  # --- firma y sello aprobando el diseño ---

  test "el documento enseña las dos imágenes y exige firma y sello para fabricar" do
    post admin_quotes_path, params: { quote: quote_params(**design_image_params) }
    quote = Quote.last

    get print_admin_quote_path(quote)
    assert_response :success
    assert_includes response.body, "Diseño de la funda"
    assert_includes response.body, "FIRMADO Y SELLADO"
    assert_includes response.body, "aprobando expresamente el diseño"
    assert_includes response.body, "La firma y el sello aprueban también el DISEÑO"
    assert_equal 2, response.body.scan(rails_blob_path(quote.case_front_image)).size +
                    response.body.scan(rails_blob_path(quote.case_back_image)).size
  end

  # --- productos con arte: hay que revisar el diseño ---

  test "con la etiqueta del nombre avisa en pantalla y lo deja escrito en los comentarios" do
    label = Product.create!(name: "Etiqueta blanca para poner el nombre", shopify_handle: Product::NAME_LABEL_HANDLE,
                            active: false, vat_percentage: 21, price: BigDecimal("0.42"))
    label.price_tiers.create!(min_units: 1, unit_price: BigDecimal("0.35"))

    post admin_quotes_path, params: { quote: quote_params(**design_image_params,
      quote_lines_attributes: { "0" => { product_id: label.id, quantity: 100, description: "", unit_price: "" } }) }
    quote = Quote.last

    assert quote.needs_design_review?
    assert_match(/REVISAR EL DISEÑO/, flash[:alert])

    comment = quote.comments.sole
    assert_match(/REVISAR EL DISEÑO/, comment.body)
    assert_match(/etiqueta blanca para poner el nombre/, comment.body)
    assert_equal users(:one), comment.user

    get print_admin_quote_path(quote)
    assert_includes response.body, "ATENCIÓN"
  end

  test "con personalización DTF avisa igual, también cuando va dentro de un pack" do
    dtf = Product.create!(name: "Personalización DTF funda", vat_percentage: 21, price: BigDecimal("2.42"))
    pack = Product.create!(name: "Pack 25 bolsas + DTF", vat_percentage: 21, price: BigDecimal("100"), pack: true)
    pack.pack_items.create!(component: dtf, quantity: 25)

    post admin_quotes_path, params: { quote: quote_params(**design_image_params,
      quote_lines_attributes: { "0" => { product_id: pack.id, quantity: 2, description: "", unit_price: "100" } }) }
    quote = Quote.last

    assert quote.needs_design_review?, "el DTF del pack cuenta igual que el suelto"
    assert_match(/personalización con DTF/, quote.comments.sole.body)
  end

  test "sin productos con arte no se avisa ni se escribe comentario" do
    post admin_quotes_path, params: { quote: quote_params(**design_image_params) }
    quote = Quote.last

    assert_not quote.needs_design_review?
    assert_nil flash[:alert]
    assert_empty quote.comments

    get print_admin_quote_path(quote)
    assert_not_includes response.body, "ATENCIÓN"
  end

  # --- duplicar ---

  test "duplicar arrastra el diseño, que es obligatorio en la copia" do
    post admin_quotes_path, params: { quote: quote_params(**design_image_params) }
    original = Quote.last

    assert_difference -> { Quote.count }, 1 do
      post duplicate_admin_quote_path(original)
    end

    copia = Quote.last
    assert_not_equal original, copia
    assert copia.case_images?
    assert_equal original.case_front_image.blob, copia.case_front_image.blob
  end

  test "duplicar uno sin diseño avisa en vez de reventar" do
    quote = create_quote(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0,
                         quote_lines_attributes: { "0" => { description: "P", quantity: 1, unit_price: 10, vat_rate: 21 } })
    quote.case_front_image.purge

    assert_no_difference -> { Quote.count } do
      post duplicate_admin_quote_path(quote)
    end

    assert_redirected_to admin_quote_path(quote)
    assert_match(/no tiene las dos imágenes del diseño/, flash[:alert])
  end
end
