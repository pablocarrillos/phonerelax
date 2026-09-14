require "test_helper"

# En el seguimiento público de un pedido, el personal con sesión iniciada tiene
# un atajo a la ficha de datos del pedido en el admin; el cliente no lo ve.
class OrderAdminLinkTest < ActionDispatch::IntegrationTest
  setup { @order = orders(:uno) }

  test "un cliente sin sesión no ve el enlace a la ficha del pedido" do
    get order_status_path(@order.number)
    assert_response :success
    assert_select "a[href=?]", admin_order_path(@order), count: 0
  end

  test "un admin con sesión ve el enlace del seguimiento a la ficha del pedido" do
    sign_in_as(users(:one))
    get order_status_path(@order.number)
    assert_response :success
    assert_select "a[href=?]", admin_order_path(@order), text: "Ver la ficha del pedido (admin)"
  end
end
