require "test_helper"

# El imán solo se vende a centros educativos: la ficha, el carrito y el pedido
# lo avisan, en el idioma de la página.
class SchoolsOnlyNoticeTest < ActionDispatch::IntegrationTest
  setup do
    @iman = Product.create!(name: "Imán PhoneRelax", price: 59.90, stock: 10, schools_only: true, shopify_handle: "iman-phonerelax")
    @iman.product_images.create!(url: "/images/products/iman-1.jpg", position: 1)
  end

  test "la ficha avisa en cada idioma y los demás productos no" do
    get product_page_path(@iman)
    assert_response :success
    assert_includes response.body, "Solo para centros educativos"
    assert_includes response.body, "No se vende a particulares."

    { "en" => "Educational institutions only", "pt" => "Apenas para estabelecimentos de ensino",
      "fr" => "Réservé aux établissements d&#39;enseignement", "de" => "Nur für Bildungseinrichtungen",
      "sv" => "Endast för utbildningsinstitutioner" }.each do |locale, title|
      get product_page_path(@iman, locale: locale)
      assert_response :success
      assert_includes response.body, title, "aviso en #{locale}"
    end

    get product_page_path(products(:funda))
    assert_not_includes response.body, "Solo para centros educativos"
  end

  test "el carrito y el pedido llevan la etiqueta" do
    post cart_add_path(@iman), params: { quantity: 1 }
    get cart_path
    assert_includes response.body, "schools-only-tag"
    assert_includes response.body, "Solo para centros educativos"

    get new_order_path
    assert_includes response.body, "Solo para centros educativos"
  end
end
