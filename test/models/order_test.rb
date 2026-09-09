require "test_helper"

class OrderTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers
  include ActionMailer::TestHelper

  def pending_order(quantity: 1)
    order = Order.create!(customer_name: "Ana", email: "a@x.com", phone: "612345678", address: "C 1",
                          city: "Madrid", postal_code: "28001", province: "Madrid", country: "España", locale: "es")
    order.order_lines.create!(product: products(:funda), quantity: quantity, unit_price: products(:funda).price)
    order
  end

  test "el número de pedido lleva 10 caracteres de entropía (da acceso a la página de estado)" do
    order = pending_order

    assert_match(/\APR-[A-Z0-9]{10}\z/, order.number)
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

  test "un pedido sin pagar no se puede marcar como enviado" do
    order = pending_order
    assert_nil order.next_status

    order.advance_status!(tracking_carrier: "SEUR")
    assert_equal "creado", order.status

    order.mark_paid!(manual: true)
    assert_equal "enviado", order.next_status
  end

  test "advance_status! a enviado guarda transportista y nº de seguimiento" do
    order = pending_order.tap { |o| o.mark_paid!(manual: true) }
    order.advance_status!(tracking_carrier: "SEUR", tracking_number: "ABC123")

    assert_equal "enviado", order.status
    assert_equal "SEUR", order.tracking_carrier
    assert_equal "ABC123", order.tracking_number
  end

  test "revert_status! retrocede un paso y lo registra" do
    order = pending_order.tap { |o| o.mark_paid!(manual: true) }
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

  test "abandoned_pending_reminder: solo pendientes con +3h, sin recordatorio y posteriores al estreno" do
    travel_to Order::ABANDONED_REMINDER_SINCE + 3.days do
      abandonado = pending_order
      abandonado.update!(created_at: 4.hours.ago)
      reciente = pending_order
      reciente.update!(created_at: 1.hour.ago)
      pagado = pending_order
      pagado.update!(created_at: 4.hours.ago, payment_status: :pagado)
      avisado = pending_order
      avisado.update!(created_at: 4.hours.ago, payment_reminder_sent_at: 30.minutes.ago)
      antiguo = pending_order
      antiguo.update!(created_at: Order::ABANDONED_REMINDER_SINCE - 1.day)

      assert_equal [ abandonado.id ], Order.abandoned_pending_reminder.ids
    end
  end

  test "send_abandoned_reminders! envía una sola vez, sella la fecha y deja evento" do
    travel_to Order::ABANDONED_REMINDER_SINCE + 3.days do
      order = pending_order
      order.update!(created_at: 4.hours.ago)

      assert_emails 1 do
        Order.send_abandoned_reminders!
      end
      order.reload
      assert order.payment_reminder_sent_at.present?
      assert_includes order.order_events.pluck(:event), "recordatorio de carrito (automático)"
      mail = ActionMailer::Base.deliveries.last
      assert_equal [ order.email ], mail.to
      assert_includes mail.body.decoded, "/pagar"

      assert_emails 0 do # no repite
        Order.send_abandoned_reminders!
      end
    end
  end

  test "send_payment_reminder! manual envía una sola vez y deja evento; nunca a pagados" do
    order = pending_order

    assert_enqueued_emails 1 do
      assert order.send_payment_reminder!
    end
    assert order.reload.payment_reminder_sent?
    assert_includes order.order_events.pluck(:event), "recordatorio de carrito (manual)"

    assert_enqueued_emails 0 do # ya lo recibió: no se repite
      assert_not order.send_payment_reminder!
    end
    assert_equal 1, order.order_events.where("event LIKE 'recordatorio de carrito%'").count

    paid = pending_order
    paid.update!(payment_status: :pagado)
    assert_enqueued_emails 0 do
      assert_not paid.send_payment_reminder!
    end
  end

  test "tras el recordatorio manual el cron no envía el automático, y viceversa" do
    travel_to Order::ABANDONED_REMINDER_SINCE + 3.days do
      manual = pending_order
      manual.update!(created_at: 4.hours.ago)
      manual.send_payment_reminder!
      assert_not_includes Order.abandoned_pending_reminder.ids, manual.id
      assert_emails 0 do
        Order.send_abandoned_reminders!
      end

      auto = pending_order
      auto.update!(created_at: 4.hours.ago)
      assert_emails 1 do
        Order.send_abandoned_reminders!
      end
      assert_enqueued_emails 0 do
        assert_not auto.reload.send_payment_reminder!
      end
      assert_equal [ "recordatorio de carrito (automático)" ],
                   auto.order_events.where("event LIKE 'recordatorio de carrito%'").pluck(:event)
    end
  end
end
