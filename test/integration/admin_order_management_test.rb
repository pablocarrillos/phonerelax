require "test_helper"

class AdminOrderManagementTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup { sign_in_as(users(:one)) }

  def pending_order
    order = Order.create!(customer_name: "Ana", email: "a@x.com", phone: "612345678", address: "C 1",
                          city: "Madrid", postal_code: "28001", province: "Madrid", country: "España", locale: "es")
    order.order_lines.create!(product: products(:funda), quantity: 1, unit_price: products(:funda).price)
    order
  end

  test "el listado se renderiza con la barra de resumen" do
    get admin_orders_path
    assert_response :success
    assert_select "h1", "Pedidos"
  end

  test "la ficha del pedido se renderiza (acciones y notas)" do
    get admin_order_path(pending_order)
    assert_response :success
    assert_select "h2", text: "Notas internas"
  end

  test "marcar como pagado (cobro manual)" do
    order = pending_order
    post mark_paid_admin_order_path(order)
    assert_redirected_to admin_order_path(order)
    assert order.reload.pago_pagado?
    assert order.paid_manually?
  end

  test "marcar como enviado con seguimiento" do
    order = pending_order
    patch advance_admin_order_path(order), params: { tracking_carrier: "SEUR", tracking_number: "XYZ9" }
    assert_equal "enviado", order.reload.status
    assert_equal "XYZ9", order.tracking_number
  end

  test "deshacer un avance de estado" do
    order = pending_order
    order.advance_status!
    patch revert_admin_order_path(order)
    assert_equal "creado", order.reload.status
  end

  test "guardar notas internas" do
    order = pending_order
    patch admin_order_path(order), params: { order: { admin_notes: "Llamar antes de enviar" } }
    assert_equal "Llamar antes de enviar", order.reload.admin_notes
  end

  test "exportar pedidos a CSV" do
    order = pending_order
    get admin_orders_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, order.number
  end

  test "albarán imprimible se renderiza" do
    order = pending_order
    get packing_slip_admin_order_path(order)
    assert_response :success
    assert_includes response.body, "Albarán"
    assert_includes response.body, order.number
  end

  test "filtros de pendientes antiguos y de fechas se renderizan" do
    get admin_orders_path(stale: 1)
    assert_response :success
    get admin_orders_path(from: "2020-01-01", to: Date.current.iso8601)
    assert_response :success
  end

  test "el recordatorio de pago envía el email al cliente" do
    order = pending_order
    assert_emails 1 do
      post payment_reminder_admin_order_path(order)
    end
    assert_redirected_to admin_order_path(order)
    assert_equal [ order.email ], ActionMailer::Base.deliveries.last.to
  end

  test "el recordatorio no se envía si el pedido ya está pagado" do
    order = pending_order
    order.mark_paid!(manual: true)
    perform_enqueued_jobs # entrega el email de «pagado» para dejar la cola limpia
    assert_emails 0 do
      post payment_reminder_admin_order_path(order)
    end
    assert_redirected_to admin_order_path(order)
  end

  test "avanzar a enviado notifica al cliente por email" do
    order = pending_order
    assert_emails 1 do
      patch advance_admin_order_path(order), params: { tracking_carrier: "SEUR", tracking_number: "XYZ9" }
    end
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ order.email ], mail.to
    assert_includes mail.body.decoded, "XYZ9"
  end

  test "el panel exige sesión iniciada" do
    sign_out
    get admin_orders_path
    assert_redirected_to new_session_path
  end
end
