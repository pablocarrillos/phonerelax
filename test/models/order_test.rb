require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def pending_order(quantity: 1)
    order = Order.create!(customer_name: "Ana", email: "a@x.com", address: "C 1",
                          city: "Madrid", postal_code: "28001", country: "España", locale: "es")
    order.order_lines.create!(product: products(:funda), quantity: quantity, unit_price: products(:funda).price)
    order
  end

  test "mark_paid! manual marca el cobro manual, deja evento y descuenta stock" do
    products(:funda).update!(stock: 5)
    order = pending_order(quantity: 2)

    assert_difference -> { products(:funda).reload.stock }, -2 do
      order.mark_paid!(manual: true)
    end
    assert order.pago_pagado?
    assert order.paid_manually?
    assert_includes order.order_events.pluck(:event), "pagado (manual)"
  end

  test "advance_status! a enviado guarda transportista y nº de seguimiento" do
    order = pending_order
    order.advance_status!(tracking_carrier: "SEUR", tracking_number: "ABC123")

    assert_equal "enviado", order.status
    assert_equal "SEUR", order.tracking_carrier
    assert_equal "ABC123", order.tracking_number
  end

  test "revert_status! retrocede un paso y lo registra" do
    order = pending_order
    order.advance_status!
    assert_equal "enviado", order.status

    order.revert_status!
    assert_equal "creado", order.status
    assert_includes order.order_events.pluck(:event), "revertido a creado"
  end

  test "tracking_url construye el enlace del transportista reconocido" do
    order = Order.new(tracking_carrier: "SEUR", tracking_number: "ABC123")
    assert_includes order.tracking_url, "seur.com"
    assert_includes order.tracking_url, "ABC123"

    assert_nil Order.new(tracking_carrier: "Transportista X", tracking_number: "1").tracking_url
    assert_nil Order.new(tracking_carrier: "SEUR", tracking_number: nil).tracking_url
  end
end
