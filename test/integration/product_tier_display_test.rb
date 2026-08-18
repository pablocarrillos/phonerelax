require "test_helper"

# El escalado de precios en la ficha: aviso traducido y datos embebidos para
# que el navegador recalcule precio y descuento al cambiar la cantidad.
class ProductTierDisplayTest < ActionDispatch::IntegrationTest
  setup do
    @product = Product.create!(name: "Taquilla individual", price: 24.95, vat_percentage: 21,
                               active: true, stock: 100)
    @product.price_tiers.create!(min_units: 1, unit_price: 20.6198)   # 24,95 con IVA
    @product.price_tiers.create!(min_units: 10, unit_price: 18.1818)  # 22,00 con IVA
  end

  test "la ficha lleva el aviso, los tramos con IVA y las plantillas traducidas" do
    get product_page_path(@product)

    assert_response :success
    assert_select ".tier-hint", text: "Obtén descuentos automáticamente al comprar más unidades"
    assert_select "[data-controller='tier-quantity']"
    assert_select "[data-tier-quantity-target='live']"
    # el JSON viaja escapado dentro del atributo data
    assert_includes @response.body, "&quot;min&quot;:10"
    assert_includes @response.body, "&quot;unit&quot;:22.0"
  end

  test "en inglés el aviso va traducido" do
    get product_page_path(@product, locale: :en)

    assert_select ".tier-hint", text: "Volume discounts are applied automatically as you buy more units"
  end

  test "un producto sin escalado no enseña el aviso ni el controlador" do
    plain = Product.create!(name: "Llavero", price: 5, vat_percentage: 21, active: true, stock: 10)
    plain.price_tiers.create!(min_units: 1, unit_price: 4.1322)

    get product_page_path(plain)

    assert_response :success
    assert_select ".tier-hint", count: 0
    assert_select "[data-controller='tier-quantity']", count: 0
  end

  test "las seis lenguas tienen las claves del escalado" do
    %i[es en fr pt de sv].each do |locale|
      %w[tier_hint tier_total tier_discount].each do |key|
        text = I18n.t("product.#{key}", locale: locale, total: "x", units: 1, pct: 1, default: nil)
        assert text.present?, "falta product.#{key} en #{locale}"
      end
    end
  end
end
