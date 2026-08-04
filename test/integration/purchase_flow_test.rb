require "test_helper"

# Flujo de compra completo: carrito → datos del cliente → Checkout de Stripe → webhook.
# Las llamadas a la API de Stripe se stubbean; el webhook se firma con el secreto de test,
# así que la verificación de firma del controlador se ejecuta de verdad.
class PurchaseFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  WEBHOOK_SECRET = "whsec_test_secret".freeze
  FakeCheckoutSession = Struct.new(:id, :url, :payment_status)

  setup do
    @funda = products(:funda)
    @timestamp_was = InvisibleCaptcha.timestamp_enabled
    @spinner_was = InvisibleCaptcha.spinner_enabled
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false
    @secret_was = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = WEBHOOK_SECRET
  end

  teardown do
    InvisibleCaptcha.timestamp_enabled = @timestamp_was
    InvisibleCaptcha.spinner_enabled = @spinner_was
    ENV["STRIPE_WEBHOOK_SECRET"] = @secret_was
  end

  test "compra completa: carrito, pedido, Checkout y webhook que confirma el pago" do
    post cart_add_path(product_id: @funda), params: { quantity: 2 }

    post orders_path, params: { order: customer_data }
    order = Order.find_by!(email: customer_data[:email])
    assert_redirected_to order_pay_path(order.number)
    assert_equal 2, order.order_lines.sum(:quantity)
    # 2 × 9,95 + transporte (5,95 + 2 × 1) = 27,85
    assert_equal BigDecimal("27.85"), order.total
    assert_equal [ "creado" ], order.order_events.pluck(:event)

    checkout = FakeCheckoutSession.new("cs_test_ok", "https://checkout.stripe.com/c/pay/cs_test_ok")
    with_stripe_session_stub(:create, checkout) do
      post order_payments_path(order.number)
    end
    assert_redirected_to checkout.url
    assert_equal "cs_test_ok", order.reload.stripe_session_id
    assert session[:cart].blank?, "el carrito debe vaciarse al ir al pago"

    assert_emails 2 do # confirmación al cliente + aviso interno a la tienda
      post_webhook "cs_test_ok"
      assert_response :ok
    end
    order.reload
    assert order.pago_pagado?
    assert_not order.paid_manually?
    assert_equal 8, @funda.reload.stock, "el pago descuenta el stock"
    assert_includes order.order_events.pluck(:event), "pagado"
    mail = ActionMailer::Base.deliveries.find { |m| m.to == [ order.email ] }
    assert mail, "el cliente recibe su confirmación"
    assert_includes mail.subject, order.number
    shop_mail = ActionMailer::Base.deliveries.find { |m| m.to == [ "phonerelaxstore@gmail.com" ] }
    assert shop_mail, "la tienda recibe el aviso de venta"
    assert_includes shop_mail.body.decoded, order.address

    # La página de estado agradece la compra y enlaza cada producto comprado.
    get order_status_path(order.number)
    assert_response :success
    assert_includes response.body, "Gracias por tu compra"
    assert_includes response.body, product_page_path(@funda)
  end

  test "el webhook es idempotente: un reintento no repite stock ni email" do
    order = paid_order
    stock_before = @funda.reload.stock
    assert_emails 0 do
      post_webhook order.stripe_session_id
      assert_response :ok
    end
    assert_equal stock_before, @funda.reload.stock
    assert_equal 1, order.order_events.where(event: "pagado").count
  end

  test "un webhook con firma inválida se rechaza sin tocar el pedido" do
    order = order_with_session("cs_test_firma")
    payload = webhook_payload("cs_test_firma")
    post "/stripe/webhook", params: payload,
         headers: { "CONTENT_TYPE" => "application/json", "HTTP_STRIPE_SIGNATURE" => "t=1,v1=firma-falsa" }
    assert_response :bad_request
    assert order.reload.pago_pendiente?
  end

  test "un webhook de una sesión desconocida responde ok y no marca nada" do
    order = order_with_session("cs_test_mio")
    assert_emails 0 do
      post_webhook "cs_test_de_otro"
      assert_response :ok
    end
    assert order.reload.pago_pendiente?
  end

  test "la vuelta de Stripe confirma el pago si el webhook aún no ha llegado" do
    order = order_with_session("cs_test_retorno")
    paid_session = FakeCheckoutSession.new("cs_test_retorno", nil, "paid")
    assert_emails 2 do # confirmación al cliente + aviso interno a la tienda
      with_stripe_session_stub(:retrieve, paid_session) do
        get order_success_path(order.number)
      end
    end
    assert_redirected_to order_status_path(order.number)
    assert order.reload.pago_pagado?
  end

  test "si el stock baja antes de confirmar, el pedido no se crea" do
    post cart_add_path(product_id: @funda), params: { quantity: 2 }
    @funda.update!(stock: 1)
    assert_no_difference "Order.count" do
      post orders_path, params: { order: customer_data }
    end
    assert_redirected_to cart_path
  end

  test "un pedido con datos incompletos vuelve al formulario" do
    post cart_add_path(product_id: @funda)
    assert_no_difference "Order.count" do
      post orders_path, params: { order: customer_data.merge(email: "") }
    end
    assert_response :unprocessable_entity
  end

  test "todos los datos del cliente son obligatorios" do
    post cart_add_path(product_id: @funda)
    customer_data.each_key do |field|
      assert_no_difference "Order.count", "el campo #{field} debería ser obligatorio" do
        post orders_path, params: { order: customer_data.merge(field => "") }
      end
      assert_response :unprocessable_entity
    end
  end

  private

  # Sustituye un método de clase de Stripe::Checkout::Session durante el bloque
  # (minitest 6 ya no trae minitest/mock; esto evita depender de otra gem).
  def with_stripe_session_stub(method_name, result)
    singleton = Stripe::Checkout::Session.singleton_class
    original = Stripe::Checkout::Session.method(method_name)
    singleton.define_method(method_name) { |*_args, **_kwargs| result }
    yield
  ensure
    singleton.define_method(method_name, original)
  end

  def customer_data
    { customer_name: "Cliente Prueba", email: "cliente@example.com", phone: "612345678",
      address: "Calle Mayor 1", city: "Madrid", postal_code: "28001",
      province: "Madrid", country: "España" }
  end

  # Pedido ya creado y con sesión de Stripe asignada, listo para recibir el webhook.
  def order_with_session(session_id, quantity: 2)
    post cart_add_path(product_id: @funda), params: { quantity: quantity }
    post orders_path, params: { order: customer_data }
    Order.find_by!(email: customer_data[:email]).tap do |order|
      order.update!(stripe_session_id: session_id)
    end
  end

  def paid_order
    order_with_session("cs_test_pagado").tap do |order|
      perform_enqueued_jobs { post_webhook("cs_test_pagado") }
      assert order.reload.pago_pagado?
      ActionMailer::Base.deliveries.clear
    end
  end

  def webhook_payload(session_id)
    { id: "evt_test_1", object: "event", type: "checkout.session.completed",
      data: { object: { id: session_id, object: "checkout.session" } } }.to_json
  end

  # Firma real del esquema de Stripe (t=...,v1=HMAC-SHA256), como la calcula stripe-ruby.
  def stripe_signature(payload, timestamp: Time.now.to_i)
    digest = OpenSSL::HMAC.hexdigest("SHA256", WEBHOOK_SECRET, "#{timestamp}.#{payload}")
    "t=#{timestamp},v1=#{digest}"
  end

  def post_webhook(session_id)
    payload = webhook_payload(session_id)
    post "/stripe/webhook", params: payload,
         headers: { "CONTENT_TYPE" => "application/json", "HTTP_STRIPE_SIGNATURE" => stripe_signature(payload) }
  end
end
