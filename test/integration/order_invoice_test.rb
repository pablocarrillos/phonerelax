require "test_helper"

# Factura opcional en el checkout: datos fiscales obligatorios y válidos cuando
# el cliente la pide, y comprobación VIES del NIF-IVA europeo.
class OrderInvoiceTest < ActionDispatch::IntegrationTest
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

  test "pedido con factura y CIF válido guarda los datos fiscales y mantiene el IVA" do
    post cart_add_path(product_id: @funda), params: { quantity: 1 }
    assert_difference "Order.count", 1 do
      post orders_path, params: { order: base_data.merge(
        needs_invoice: "1", tax_name: "ACME SL", tax_id: "A58818501",
        tax_address: "Calle Fiscal 2", tax_city: "Madrid", tax_postal_code: "28002",
        tax_province: "Madrid", tax_country: "España (Península)") }
    end
    order = Order.last
    assert order.needs_invoice
    assert_equal "ACME SL", order.tax_name
    assert_equal "A58818501", order.tax_id
    assert_not order.vat_exempt, "con los interruptores en false la venta lleva IVA"
  end

  test "pedido con factura y NIF inválido vuelve al formulario" do
    post cart_add_path(product_id: @funda), params: { quantity: 1 }
    assert_no_difference "Order.count" do
      post orders_path, params: { order: base_data.merge(
        needs_invoice: "1", tax_name: "Juan", tax_id: "12345678A",
        tax_address: "X", tax_city: "M", tax_postal_code: "28001",
        tax_province: "M", tax_country: "España (Península)") }
    end
    assert_response :unprocessable_entity
  end

  test "pedido sin factura no exige datos fiscales" do
    post cart_add_path(product_id: @funda), params: { quantity: 1 }
    assert_difference "Order.count", 1 do
      post orders_path, params: { order: base_data }
    end
    assert_not Order.last.needs_invoice
  end

  test "el endpoint VIES devuelve JSON con el resultado" do
    original = Vies.method(:check)
    Vies.define_singleton_method(:check) { |_vat| { ok: true, valid: true, name: "TEST GMBH" } }
    get vies_check_path(vat: "DE123456789")
    assert_response :success
    assert_equal true, JSON.parse(response.body)["valid"]
  ensure
    Vies.define_singleton_method(:check, original)
  end
end
