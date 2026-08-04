require "test_helper"

# Configuración del transporte: base por país y coste por unidad de producto.
class AdminShippingTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "la pantalla lista los 27 países de la UE y los productos" do
    get admin_shipping_path
    assert_response :success
    assert_select "h1", "Transporte"
    Order::EU_COUNTRIES.each { |country| assert_includes response.body, country }
    assert_includes response.body, products(:funda).name
  end

  test "guardar la tarifa de un país y el coste de un producto cambia el envío" do
    patch admin_shipping_path, params: { rates: { "Francia" => "11,50" } }
    assert_redirected_to admin_shipping_path
    assert_equal BigDecimal("11.5"), ShippingRate.base_for("Francia")

    patch admin_shipping_path, params: { product_costs: { products(:funda).id => "2.25" } }
    assert_equal BigDecimal("2.25"), products(:funda).reload.shipping_unit_cost

    order = Order.new(country: "Francia")
    order.order_lines.build(product: products(:funda), quantity: 4, unit_price: products(:funda).price)
    # 11,50 de base + 4 uds. × 2,25 = 20,50
    assert_equal BigDecimal("20.5"), order.compute_shipping
  end

  test "sin tarifa guardada se aplican los valores históricos" do
    ShippingRate.delete_all
    order = Order.new(country: "España")
    order.order_lines.build(product: products(:funda), quantity: 2, unit_price: products(:funda).price)
    assert_equal BigDecimal("7.95"), order.compute_shipping # 5,95 + 2 × 1,00

    foreign = Order.new(country: "Portugal")
    foreign.order_lines.build(product: products(:funda), quantity: 2, unit_price: products(:funda).price)
    assert_equal BigDecimal("15.95"), foreign.compute_shipping # 13,95 + 2 × 1,00
  end

  test "una tarifa negativa se rechaza" do
    patch admin_shipping_path, params: { rates: { "Italia" => "-3" } }
    assert_redirected_to admin_shipping_path
    assert_nil ShippingRate.find_by(country: "Italia")
  end
end
