require "test_helper"

# Gestión de productos en el admin: portada subida como adjunto y formulario
# con pestañas por idioma.
class AdminProductManagementTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @product = products(:funda)
  end

  test "el formulario muestra la subida de portada y las pestañas por idioma" do
    get edit_admin_product_path(@product)
    assert_response :success
    assert_select "input[type=file][name='product[cover_image]']"
    assert_select "input[name='product[image_url]']", 0 # la ruta ya no se enseña
    assert_select ".lang-tabs .tab-button", 5
    assert_select ".lang-tabs .tab-panel", 5
    assert_select "input[name='product[position]']", 0 # la posición ya no se edita a mano
    # Escalado: plantilla y botón para añadir tramos nuevos sin límite.
    assert_select "template[data-price-tiers-target='template']"
    assert_select "button[data-action='price-tiers#addRow']"
    # Pack: el formulario reacciona al check (escalado oculto, notas automáticas).
    assert_select "form[data-controller='pack-form']"
    assert_select "input[data-pack-form-target='price']", 0 # el precio ya no se teclea: sale del escalado
    assert_select "input[data-pack-form-target='stock']"
  end

  test "la lista permite reordenar arrastrando y guarda el nuevo orden" do
    get admin_products_path
    assert_select "tbody[data-controller='reorder']"
    assert_select ".drag-handle", Product.count

    funda = products(:funda)
    iman = products(:iman)
    patch reorder_admin_products_path, params: { ids: [ iman.id, funda.id ] }, as: :json
    assert_response :success
    assert_equal 1, iman.reload.position
    assert_equal 2, funda.reload.position
  end

  test "reordenar sin ids no cambia nada" do
    patch reorder_admin_products_path, params: { ids: [] }, as: :json
    assert_response :unprocessable_entity
  end

  test "el precio de tienda sale del tramo base del escalado (el campo precio ya no existe)" do
    tier = @product.price_tiers.find_by!(min_units: 1)

    patch admin_product_path(@product), params: { product: {
      name: @product.name,
      price_tiers_attributes: { "0" => { id: tier.id, min_units: 1, unit_price: "10.00" } }
    } }
    assert_redirected_to admin_products_path
    assert_equal BigDecimal("12.1"), @product.reload.price, "10,00 sin IVA × 21 % = 12,10 de PVP"

    get edit_admin_product_path(@product)
    assert_select "input#product_price", 0, "el campo de precio a mano ya no está"
  end

  test "sin el tramo «desde 1 unidad» el producto no se guarda desde el admin" do
    tier = @product.price_tiers.find_by!(min_units: 1)

    patch admin_product_path(@product), params: { product: {
      name: @product.name,
      price_tiers_attributes: { "0" => { id: tier.id, _destroy: "1" } }
    } }

    assert_response :unprocessable_entity
    assert_includes response.body, "desde 1 unidad"
    assert @product.reload.price_tiers.exists?(min_units: 1), "el tramo base no se borra"
  end

  test "subir una portada nueva la adjunta y pasa a usarse en la tienda" do
    patch admin_product_path(@product), params: { product: {
      name: @product.name, price: @product.price,
      cover_image: fixture_file_upload("cover.png", "image/png")
    } }
    assert_redirected_to admin_products_path
    @product.reload
    assert @product.cover_image.attached?
    assert_match %r{/rails/active_storage/blobs/}, @product.cover_url
  end

  test "sin galería propia, la ficha usa la portada subida" do
    iman = products(:iman)
    iman.cover_image.attach(io: file_fixture("cover.png").open, filename: "cover.png", content_type: "image/png")
    assert_equal [ iman.cover_url ], iman.gallery_urls
  end

  test "sin portada subida se mantiene la ruta antigua de image_url" do
    @product.update!(image_url: "/images/products/antigua.jpg")
    assert_equal "/images/products/antigua.jpg", @product.cover_url
  end

  test "la galería acepta subir varios ficheros a la vez" do
    assert_difference -> { @product.product_images.count }, 2 do
      post admin_product_product_images_path(@product),
           params: { files: [ fixture_file_upload("cover.png", "image/png"),
                              fixture_file_upload("cover.png", "image/png") ] }
    end
    assert_redirected_to edit_admin_product_path(@product)
    nuevas = @product.product_images.ordered.last(2)
    assert nuevas.all? { |image| image.file.attached? }
    assert_match %r{/rails/active_storage/blobs/}, nuevas.first.src
    assert_includes @product.reload.gallery_urls, nuevas.first.src
  end

  test "las imágenes históricas por URL siguen funcionando en la galería" do
    assert_equal [ "https://example.com/frontal.jpg", "https://example.com/trasera.jpg" ],
                 @product.gallery_urls
  end
end
