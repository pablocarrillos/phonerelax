require "test_helper"

# El carrito debe entender las URLs con slug (Product#to_param) y las antiguas por id.
class CartFlowTest < ActionDispatch::IntegrationTest
  setup { @funda = products(:funda) }

  test "añadir desde la portada con la URL de slug" do
    post cart_add_path(product_id: @funda)
    assert_redirected_to cart_path
    assert_equal({ @funda.id.to_s => 1 }, session[:cart])
  end

  test "añadir con la URL antigua por id numérico" do
    post cart_add_path(product_id: @funda.id)
    assert_redirected_to cart_path
    assert_equal({ @funda.id.to_s => 1 }, session[:cart])
  end

  test "cambiar la cantidad desde el carrito" do
    post cart_add_path(product_id: @funda)
    patch cart_update_path(product_id: @funda), params: { quantity: 3 }
    assert_redirected_to cart_path
    assert_equal({ @funda.id.to_s => 3 }, session[:cart])
  end

  test "quitar un producto del carrito" do
    post cart_add_path(product_id: @funda)
    delete cart_remove_path(product_id: @funda)
    assert_redirected_to cart_path
    assert session[:cart].blank?
  end

  test "la cantidad se capa al stock disponible" do
    post cart_add_path(product_id: @funda), params: { quantity: 99 }
    assert_redirected_to cart_path
    assert_equal({ @funda.id.to_s => @funda.stock }, session[:cart])
  end

  test "un producto agotado no se añade" do
    post cart_add_path(product_id: products(:iman))
    assert_response :redirect
    assert session[:cart].blank?
  end

  test "el carrito se renderiza con sus líneas" do
    post cart_add_path(product_id: @funda)
    get cart_path
    assert_response :success
    assert_includes response.body, @funda.name
  end
end
