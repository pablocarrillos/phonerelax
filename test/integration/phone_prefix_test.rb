require "test_helper"

# Selector de prefijo telefónico del checkout: compone el número internacional
# con el prefijo elegido y valida el teléfono con o sin prefijo.
class PhonePrefixTest < ActionDispatch::IntegrationTest
  setup do
    @funda = products(:funda)
    @cap_ts = InvisibleCaptcha.timestamp_enabled
    @cap_sp = InvisibleCaptcha.spinner_enabled
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false
  end

  teardown do
    InvisibleCaptcha.timestamp_enabled = @cap_ts
    InvisibleCaptcha.spinner_enabled = @cap_sp
  end

  def base_data
    { customer_name: "Cliente", email: "c@example.com", phone: "612345678",
      address: "Calle 1", city: "Madrid", postal_code: "28001", province: "Madrid",
      country: "España (Península)" }
  end

  test "el prefijo elegido compone el teléfono internacional (quita el cero inicial francés)" do
    post cart_add_path(product_id: @funda), params: { quantity: 1 }
    assert_difference "Order.count", 1 do
      post orders_path, params: { order: base_data.merge(
        country: "Francia", phone: "06 12 34 56 78", phone_prefix: "FR") }
    end
    assert_equal "+33612345678", Order.last.phone
  end

  test "un teléfono ya internacional se respeta aunque no coincida con el país de envío" do
    post cart_add_path(product_id: @funda), params: { quantity: 1 }
    assert_difference "Order.count", 1 do
      post orders_path, params: { order: base_data.merge(phone: "+33612345678", phone_prefix: "ES") }
    end
    assert_equal "+33612345678", Order.last.phone
  end

  test "sin prefijo internacional el teléfono debe ser válido para el país de envío" do
    post cart_add_path(product_id: @funda), params: { quantity: 1 }
    assert_no_difference "Order.count" do
      post orders_path, params: { order: base_data.merge(phone: "12345", phone_prefix: "ES") }
    end
    assert_response :unprocessable_entity
  end

  test "la tienda funciona en francés" do
    get "/fr"
    assert_response :success
    assert_includes response.body, "Ajouter au panier"
    get "/fr/commande/nouvelle"
    assert_response :redirect # carrito vacío: redirige al carrito
  end
end
