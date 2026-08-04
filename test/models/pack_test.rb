require "test_helper"

# Packs: productos compuestos por otros, con precio calculado desde el escalado
# de cada componente, desglose de ahorro y stock derivado de los componentes.
class PackTest < ActiveSupport::TestCase
  setup do
    @funda = products(:funda)
    @iman = products(:iman)
    @funda.price_tiers.destroy_all
    @funda.update!(price: BigDecimal("12.10"), vat_percentage: 21, stock: 100)
    @funda.price_tiers.create!(min_units: 10, unit_price: BigDecimal("2")) # 2 sin IVA => 2,42 con IVA
    @iman.price_tiers.destroy_all
    @iman.update!(price: BigDecimal("5.00"), vat_percentage: 21, stock: 100)
  end

  def build_pack(items)
    pack = Product.new(name: "Pack de prueba", pack: true, stock: 0, vat_percentage: 21)
    items.each { |component, qty| pack.pack_items.build(component: component, quantity: qty) }
    pack.save!
    pack
  end

  test "el precio del pack usa el escalado de cada componente y se cachea en price" do
    pack = build_pack(@funda => 10, @iman => 2)
    # funda 10 uds: 2 × 1,21 = 2,42/ud × 10 = 24,20 ; imán base 5,00 × 2 = 10,00
    assert_equal BigDecimal("34.20"), pack.pack_unit_price
    assert_equal pack.pack_unit_price, pack.price_for_quantity(1)
    assert_equal pack.pack_unit_price, pack.price_for_quantity(3) # el pack no tiene escalado propio
    assert_equal pack.pack_unit_price, pack.reload.price
    assert_equal pack.pack_unit_price, pack.display_price
  end

  test "el desglose muestra el ahorro por componente" do
    pack = build_pack(@funda => 10)
    r = pack.pack_breakdown.first
    assert_equal BigDecimal("121.0"), r[:base_total]  # 12,10 × 10 sin descuento
    assert_equal BigDecimal("24.2"), r[:line_total]   # 2,42 × 10 en el pack
    assert_equal BigDecimal("96.8"), r[:saving]
    assert_equal BigDecimal("96.8"), pack.pack_total_saving
  end

  test "el stock del pack es el que permiten sus componentes" do
    @funda.update!(stock: 25)
    @iman.update!(stock: 4)
    pack = build_pack(@funda => 10, @iman => 2) # 25/10=2 ; 4/2=2 => 2
    assert_equal 2, pack.available_stock
    @iman.update!(stock: 1) # 1/2 = 0
    assert pack.out_of_stock?
  end

  test "vender un pack descuenta el stock de los componentes y se puede restaurar" do
    @funda.update!(stock: 30)
    @iman.update!(stock: 10)
    pack = build_pack(@funda => 10, @iman => 2)
    pack.consume_stock!(2) # vende 2 packs
    assert_equal 10, @funda.reload.stock # 30 - 10×2
    assert_equal 6, @iman.reload.stock   # 10 - 2×2
    pack.restore_stock!(1)
    assert_equal 20, @funda.reload.stock
    assert_equal 8, @iman.reload.stock
  end

  test "un pack no puede contener otro pack" do
    inner = build_pack(@iman => 1)
    outer = Product.new(name: "Outer", pack: true, stock: 0)
    outer.pack_items.build(component: inner, quantity: 1)
    assert_not outer.valid?
  end
end
