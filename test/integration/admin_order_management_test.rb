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

  # --- Reembolsos ---

  def paid_order(manual: false)
    order = pending_order
    order.update!(total: BigDecimal("22.90"), shipping_cost: BigDecimal("7.95"),
                  payment_status: :pagado, paid_manually: manual,
                  stripe_session_id: manual ? nil : "cs_test_abc")
    order
  end

  test "reembolso parcial vía Stripe deja el pedido pagado y anota el importe" do
    order = paid_order
    refunds = with_stripe_refund_stubs do
      post refund_admin_order_path(order), params: { amount: "10,50" }
    end
    assert_redirected_to admin_order_path(order)
    assert_equal [ { payment_intent: "pi_test_1", amount: 1050 } ], refunds
    order.reload
    assert order.pago_pagado?
    assert_equal BigDecimal("10.5"), order.refunded_amount
    assert_equal "pi_test_1", order.stripe_payment_intent_id
    assert_equal BigDecimal("12.4"), order.refundable_amount
  end

  test "reembolso total pasa el pedido a «reembolsado»" do
    order = paid_order
    refunds = with_stripe_refund_stubs do
      post refund_admin_order_path(order), params: { amount: "22.90" }
    end
    assert_equal 2290, refunds.first[:amount]
    order.reload
    assert order.pago_reembolsado?
    assert_equal BigDecimal("22.9"), order.refunded_amount
    assert_equal "reembolsado", order.order_events.last.event
  end

  test "dos reembolsos parciales acaban en «reembolsado»" do
    order = paid_order
    with_stripe_refund_stubs do
      post refund_admin_order_path(order), params: { amount: "12.90" }
      post refund_admin_order_path(order), params: { amount: "10.00" }
    end
    assert order.reload.pago_reembolsado?
  end

  test "el reembolso de un cobro manual se registra sin llamar a Stripe" do
    order = paid_order(manual: true)
    post refund_admin_order_path(order), params: { amount: "22.90" }
    assert_redirected_to admin_order_path(order)
    assert order.reload.pago_reembolsado?
  end

  test "no se puede reembolsar más de lo cobrado ni un pedido sin pagar" do
    order = paid_order
    post refund_admin_order_path(order), params: { amount: "99" }
    assert_equal 0, order.reload.refunded_amount
    unpaid = pending_order
    post refund_admin_order_path(unpaid), params: { amount: "5" }
    assert_equal 0, unpaid.reload.refunded_amount
  end

  # --- Borrado de pedidos ---

  test "borrar un pedido pendiente no toca el stock" do
    order = pending_order
    stock_was = products(:funda).stock
    assert_difference "Order.count", -1 do
      delete admin_order_path(order)
    end
    assert_redirected_to admin_orders_path
    assert_equal stock_was, products(:funda).reload.stock
  end

  test "borrar un pedido reembolsado devuelve las unidades al stock" do
    order = paid_order(manual: true)
    order.refund!(order.amount_paid)
    stock_was = products(:funda).stock
    assert_difference "Order.count", -1 do
      delete admin_order_path(order)
    end
    assert_equal stock_was + 1, products(:funda).reload.stock
  end

  test "un pedido con dinero cobrado no se puede borrar" do
    order = paid_order(manual: true)
    assert_no_difference "Order.count" do
      delete admin_order_path(order)
    end
    assert_redirected_to admin_order_path(order)
  end

  private

  # Stubs de Stripe para reembolsos: la sesión devuelve un payment_intent fijo y
  # Refund.create captura sus argumentos en la lista que se devuelve al bloque.
  def with_stripe_refund_stubs
    session = Struct.new(:payment_intent).new("pi_test_1")
    retrieve_original = Stripe::Checkout::Session.method(:retrieve)
    refund_original = Stripe::Refund.method(:create)
    refunds = []
    Stripe::Checkout::Session.singleton_class.define_method(:retrieve) { |*_args| session }
    Stripe::Refund.singleton_class.define_method(:create) { |**kwargs| refunds << kwargs; nil }
    yield
    refunds
  ensure
    Stripe::Checkout::Session.singleton_class.define_method(:retrieve, retrieve_original)
    Stripe::Refund.singleton_class.define_method(:create, refund_original)
  end
end
