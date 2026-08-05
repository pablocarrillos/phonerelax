require "test_helper"

# Reglas al tramitar el carrito: sin cantidades a 0, y si hay personalización DTF
# suelta, su total (con los de packs) debe ser >= 25 e igual al total de fundas.
class CheckoutRulesTest < ActionDispatch::IntegrationTest
  setup do
    @cap_ts = InvisibleCaptcha.timestamp_enabled
    @cap_sp = InvisibleCaptcha.spinner_enabled
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false
    @funda = Product.create!(name: "Funda Test", price: 10, stock: 1000, vat_percentage: 21, active: true)
    @dtf = Product.create!(name: "Personalización DTF test", price: 2, stock: 1000, vat_percentage: 21, active: true)
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

  def checkout
    post orders_path, params: { order: customer }
  end

  test "DTF suelta igual a fundas y >= 25: se puede tramitar" do
    post cart_add_path(product_id: @funda), params: { quantity: 25 }
    post cart_add_path(product_id: @dtf), params: { quantity: 25 }
    assert_difference "Order.count", 1 do
      checkout
    end
    assert_redirected_to order_pay_path(Order.last.number)
  end

  test "DTF suelta que no coincide con las fundas: bloquea" do
    post cart_add_path(product_id: @funda), params: { quantity: 20 }
    post cart_add_path(product_id: @dtf), params: { quantity: 25 }
    assert_no_difference "Order.count" do
      checkout
    end
    assert_redirected_to cart_path
  end

  test "DTF suelta por debajo del mínimo de 25: bloquea" do
    post cart_add_path(product_id: @funda), params: { quantity: 10 }
    post cart_add_path(product_id: @dtf), params: { quantity: 10 }
    assert_no_difference "Order.count" do
      checkout
    end
    assert_redirected_to cart_path
  end

  test "fundas sin personalización DTF: no aplica la regla" do
    post cart_add_path(product_id: @funda), params: { quantity: 30 }
    assert_difference "Order.count", 1 do
      checkout
    end
  end

  test "un pack solo (DTF = fundas dentro) no dispara la regla" do
    pack = Product.create!(name: "Pack Test", pack: true, stock: 0, vat_percentage: 21, active: true)
    pack.pack_items.create!(component: @funda, quantity: 25)
    pack.pack_items.create!(component: @dtf, quantity: 25)
    post cart_add_path(product_id: pack), params: { quantity: 1 }
    assert_difference "Order.count", 1 do
      checkout
    end
  end
end
