require "test_helper"

# Cupones: validación desde el checkout («Usar»), descuento aplicado al pedido
# y aviso al promotor cuando se paga.
class CouponsTest < ActionDispatch::IntegrationTest
  setup do
    @cap_ts = InvisibleCaptcha.timestamp_enabled
    @cap_sp = InvisibleCaptcha.spinner_enabled
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false
    @funda = Product.create!(name: "Funda Cupón", price: 10, stock: 1000, vat_percentage: 21, active: true)
  end

  teardown do
    InvisibleCaptcha.timestamp_enabled = @cap_ts
    InvisibleCaptcha.spinner_enabled = @cap_sp
  end

  def customer
    { customer_name: "Cliente", email: "c@example.com", phone: "612345678",
      address: "Calle 1", city: "Madrid", postal_code: "28001", province: "Madrid",
      country: "España (Península)" }
  end

  test "el botón «Usar» valida el cupón y distingue inexistente, caducado y agotado" do
    post coupon_validate_path, params: { code: "NADA" }, as: :json
    assert_not JSON.parse(response.body)["valid"]
    assert_includes response.body, "no existe"

    Coupon.create!(code: "CADUCADO", discount_percent: 10, ends_on: Date.yesterday)
    post coupon_validate_path, params: { code: "caducado" }, as: :json
    assert_includes response.body, "caducado"

    Coupon.create!(code: "AGOTADO", discount_percent: 10, max_uses: 1, uses_count: 1)
    post coupon_validate_path, params: { code: "AGOTADO" }, as: :json
    assert_includes response.body, "máximo de usos"

    Coupon.create!(code: "APAGADO", discount_percent: 10, enabled: false)
    post coupon_validate_path, params: { code: "APAGADO" }, as: :json
    assert_includes response.body, "no está activo"

    Coupon.create!(code: "BUENO", discount_percent: 10)
    post coupon_validate_path, params: { code: " bueno " }, as: :json
    assert JSON.parse(response.body)["valid"]
    assert_equal "BUENO", session[:coupon_code]
  end

  test "el checkout solo enseña el campo de cupón si hay cupones habilitados" do
    post cart_add_path(product_id: @funda.id)

    get new_order_path
    assert_not_includes response.body, "coupon-apply"

    Coupon.create!(code: "VISIBLE", discount_percent: 10)
    get new_order_path
    assert_includes response.body, "coupon-apply"
  end

  test "un cupón de porcentaje descuenta del total del pedido y avisa al promotor al pagar" do
    coupon = Coupon.create!(code: "P10", discount_percent: 10, notify_emails: "promo@x.com")
    post cart_add_path(product_id: @funda.id), params: { quantity: 2 }
    post coupon_validate_path, params: { code: "P10" }, as: :json

    post orders_path, params: { order: customer }
    order = Order.last
    # 2 × 10 € = 20 €; −10 % = 18 € + transporte
    assert_equal coupon, order.coupon
    assert_equal BigDecimal("2"), order.coupon_discount
    assert_equal BigDecimal("18") + order.shipping_cost, order.total

    # el IVA se rebaja proporcionalmente en el desglose
    vat_lines = BigDecimal("18") - BigDecimal("18") / BigDecimal("1.21")
    expected_vat = (vat_lines + order.shipping_cost - order.shipping_cost / BigDecimal("1.21")).round(2)
    assert_equal expected_vat, order.vat_breakdown[:vat]

    perform_enqueued_jobs # drena el aviso interno de pedido nuevo
    assert_emails 3 do # pagado (cliente) + venta (interno) + cupón (promotor)
      order.mark_paid!(manual: true)
      perform_enqueued_jobs
    end
    assert_equal 1, coupon.reload.uses_count
  end

  test "un cupón de cantidad fija nunca descuenta más que los productos" do
    Coupon.create!(code: "F50", discount_amount: 50)
    post cart_add_path(product_id: @funda.id)
    post coupon_validate_path, params: { code: "F50" }, as: :json

    post orders_path, params: { order: customer }
    order = Order.last
    assert_equal BigDecimal("10"), order.coupon_discount, "capado al total de productos"
    assert_equal order.shipping_cost, order.total, "los productos salen gratis; el transporte se paga"
  end

  test "si el cupón deja de ser válido antes de tramitar, el pedido sale sin descuento" do
    coupon = Coupon.create!(code: "FUGAZ", discount_percent: 10)
    post cart_add_path(product_id: @funda.id)
    post coupon_validate_path, params: { code: "FUGAZ" }, as: :json
    coupon.update!(enabled: false)

    post orders_path, params: { order: customer }
    order = Order.last
    assert_nil order.coupon
    assert_equal 0, order.coupon_discount
  end

  test "el reparto del descuento en Stripe cuadra al céntimo con el total" do
    otra = Product.create!(name: "Bolsa impar", price: "3.33", stock: 100, vat_percentage: 21, active: true)
    coupon = Coupon.create!(code: "RARO", discount_amount: "7.77")
    post cart_add_path(product_id: @funda.id), params: { quantity: 3 }
    post cart_add_path(product_id: otra.id), params: { quantity: 1 }
    post coupon_validate_path, params: { code: "RARO" }, as: :json
    post orders_path, params: { order: customer }
    order = Order.last

    checkout = StripeCheckout.new(order, success_url: "http://x/s", cancel_url: "http://x/c")
    cents = checkout.send(:line_items).sum { |item| item[:price_data][:unit_amount] * item[:quantity] }
    assert_equal (order.total * 100).to_i, cents
  end
  test "el admin filtra el uso de cupones por cupón y rango, con totales sin IVA, con IVA y descontado" do
    sign_in_as(users(:one))
    c1 = Coupon.create!(code: "UNO", discount_percent: 10)
    c2 = Coupon.create!(code: "DOS", discount_amount: 2)

    build_order = lambda do |coupon, discount, created_at|
      order = Order.new(customer_name: "Cliente", email: "c@example.com", phone: "612345678",
                        address: "Calle 1", city: "Madrid", postal_code: "28001", province: "Madrid",
                        country: "España (Península)", coupon: coupon, coupon_code: coupon.code,
                        coupon_discount: discount)
      order.order_lines.build(product: @funda, quantity: 2, unit_price: 10)
      order.total = 20 - discount
      order.save!
      order.update_columns(payment_status: Order.payment_statuses[:pagado], created_at: created_at)
      order
    end

    build_order.call(c1, BigDecimal("2"), Time.zone.parse("2026-08-30 10:00"))
    dos = build_order.call(c2, BigDecimal("2"), Time.zone.parse("2026-08-31 12:00"))
    fuera = build_order.call(c1, BigDecimal("2"), Time.zone.parse("2026-08-01 10:00"))

    # todos los cupones en el rango: 2 pedidos de 18 € (14,88 sin IVA), 4 € descontados
    get admin_coupons_path(from: "2026-08-29T00:00", to: "2026-08-31T23:59")
    assert_response :success
    assert_includes response.body, "2 pedidos"
    assert_includes response.body, "−4.00" # descuento total
    assert_includes response.body, "36.00" # con IVA
    assert_includes response.body, "29.76" # sin IVA (2 × 14,88)
    assert_not_includes response.body, fuera.number

    # solo el cupón UNO en el rango: 1 pedido
    get admin_coupons_path(coupon_id: c1.id, from: "2026-08-29T00:00", to: "2026-08-31T23:59")
    assert_includes response.body, "1 pedido"
    assert_includes response.body, "−2.00"
    assert_not_includes response.body, dos.number, "el pedido del otro cupón no sale"
  end
end
