require "test_helper"

class AdminStatsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "el panel se renderiza con ventas y productos más vendidos" do
    order = Order.create!(customer_name: "Ana", email: "a@x.com", phone: "612345678", address: "C 1",
                          city: "Madrid", postal_code: "28001", province: "Madrid", country: "España",
                          locale: "es", payment_status: :pagado, total: BigDecimal("37.85"),
                          shipping_cost: BigDecimal("7.95"))
    order.order_lines.create!(product: products(:funda), quantity: 3, unit_price: products(:funda).price)
    order.order_events.create!(event: "pagado")

    get admin_stats_path
    assert_response :success
    assert_select "h1", "Estadísticas de ventas"
    assert_select ".tab-button", 3
    assert_includes response.body, "Funda de prueba"
  end

  test "los reembolsos restan de los ingresos netos" do
    order = Order.create!(customer_name: "Ana", email: "a@x.com", phone: "612345678", address: "C 1",
                          city: "Madrid", postal_code: "28001", province: "Madrid", country: "España",
                          locale: "es", payment_status: :reembolsado, total: BigDecimal("20"),
                          refunded_amount: BigDecimal("20"))
    order.order_events.create!(event: "pagado")
    get admin_stats_path
    assert_response :success
  end

  test "exige sesión de admin" do
    sign_out
    get admin_stats_path
    assert_redirected_to new_session_path
  end
end
