require "test_helper"

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  SECRET = "whsec_test"

  setup do
    @old_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = SECRET
    products(:funda).update!(stock: 5)
    @order = Order.create!(customer_name: "Ana", email: "a@x.com", phone: "612345678", address: "C 1",
                           city: "Madrid", postal_code: "28001", province: "Madrid", country: "España", locale: "es")
    @order.order_lines.create!(product: products(:funda), quantity: 1, unit_price: products(:funda).price)
  end

  teardown { ENV["STRIPE_WEBHOOK_SECRET"] = @old_secret }

  test "checkout.session.completed marca pagado el pedido por stripe_session_id" do
    @order.update!(stripe_session_id: "cs_123")

    post_event(id: "cs_123", client_reference_id: nil)

    assert_response :ok
    assert @order.reload.pago_pagado?
  end

  test "sin sesión guardada, el pedido se localiza por client_reference_id" do
    post_event(id: "cs_desconocida", client_reference_id: @order.number)

    assert_response :ok
    assert @order.reload.pago_pagado?, "el respaldo por número de pedido debe marcarlo pagado"
  end

  test "una firma inválida se rechaza sin tocar nada" do
    payload = { type: "checkout.session.completed",
                data: { object: { id: "cs_123", client_reference_id: @order.number } } }.to_json
    post "/stripe/webhook", params: payload,
         headers: { "Stripe-Signature" => "t=1,v1=mala", "CONTENT_TYPE" => "application/json" }

    assert_response :bad_request
    assert_not @order.reload.pago_pagado?
  end

  private

  # Envía un evento checkout.session.completed firmado como lo haría Stripe.
  def post_event(object)
    payload = { type: "checkout.session.completed", data: { object: object } }.to_json
    timestamp = Time.now
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, SECRET)
    post "/stripe/webhook", params: payload,
         headers: { "Stripe-Signature" => Stripe::Webhook::Signature.generate_header(timestamp, signature),
                    "CONTENT_TYPE" => "application/json" }
  end
end
