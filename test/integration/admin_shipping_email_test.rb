require "test_helper"

# Botón «Enviar aviso de envío» del pedido: manda al almacén (Ana y Ginés, con
# copia a Juan Pedro) un email con la dirección, los artículos y la etiqueta A5.
class AdminShippingEmailTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "el pedido muestra el botón de aviso de envío" do
    get admin_order_path(orders(:uno))
    assert_response :success
    assert_select "form[action=?]", shipping_email_admin_order_path(orders(:uno))
  end

  test "el botón encola el email y deja constancia de cuándo se envió" do
    order = orders(:uno)
    assert_nil order.shipping_email_sent_at

    assert_enqueued_emails 1 do
      post shipping_email_admin_order_path(order)
    end
    assert_redirected_to admin_order_path(order)
    assert_not_nil order.reload.shipping_email_sent_at
    assert_equal 1, order.order_events.where(event: "aviso de envío al almacén").count,
                 "queda en el histórico del pedido"

    follow_redirect!
    assert_match "ana@servipau.com", flash[:notice]
    assert_match "Último aviso enviado", response.body
    assert_match "aviso de envío al almacén", response.body
  end
end
