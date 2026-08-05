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
    assert_select ".lang-tabs .tab-button", 4
    assert_select ".lang-tabs .tab-panel", 4
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
