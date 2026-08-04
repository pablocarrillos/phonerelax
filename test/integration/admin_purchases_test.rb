require "test_helper"

# Módulo de compras del admin: proveedores, compras con líneas y factura,
# recepción que suma stock y coste real por producto.
class AdminPurchasesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @supplier = Supplier.create!(name: "Fábrica Shenzhen", country: "China")
  end

  test "alta y edición de proveedores" do
    post admin_suppliers_path, params: { supplier: { name: "Mayorista UE", email: "ventas@mayorista.eu" } }
    assert_redirected_to admin_suppliers_path
    supplier = Supplier.find_by!(name: "Mayorista UE")
    patch admin_supplier_path(supplier), params: { supplier: { phone: "+34 900 000 000" } }
    assert_equal "+34 900 000 000", supplier.reload.phone
    get admin_suppliers_path
    assert_response :success
    assert_includes response.body, "Mayorista UE"
  end

  test "una compra con líneas, factura PDF y costes por línea se registra y calcula el coste real" do
    post admin_purchases_path, params: { purchase: {
      supplier_id: @supplier.id, ordered_on: "2026-08-01", reference: "INV-77",
      invoice: fixture_file_upload("factura.pdf", "application/pdf"),
      purchase_lines_attributes: {
        "0" => { product_id: products(:funda).id, quantity: 100, unit_cost: "2.00", shipping_cost: "15", customs_cost: "4", other_costs: "1" },
        "1" => { product_id: products(:iman).id, quantity: 50, unit_cost: "4.00", shipping_cost: "15", customs_cost: "4", other_costs: "1" },
        "2" => { product_id: "", quantity: "", unit_cost: "" } # fila vacía: se ignora
      }
    } }
    purchase = Purchase.last
    assert_redirected_to admin_purchase_path(purchase)
    assert purchase.invoice.attached?
    assert_equal 2, purchase.purchase_lines.count
    # Totales por concepto (suma de lo imputado en cada línea) y total factura.
    assert_equal BigDecimal("30"), purchase.total_shipping
    assert_equal BigDecimal("8"), purchase.total_customs
    assert_equal BigDecimal("2"), purchase.total_other
    assert_equal BigDecimal("440"), purchase.total_cost
    # Coste real/ud. = total de la línea (productos + sus extras) entre unidades.
    funda_line = purchase.purchase_lines.find_by(product: products(:funda))
    iman_line = purchase.purchase_lines.find_by(product: products(:iman))
    assert_equal BigDecimal("2.2"), purchase.landed_unit_cost(funda_line) # (200 + 20) / 100
    assert_equal BigDecimal("4.4"), purchase.landed_unit_cost(iman_line)  # (200 + 20) / 50
  end

  test "recibir una compra suma stock y deshacerla lo resta" do
    purchase = purchase_with_line(quantity: 25)
    stock_was = products(:funda).stock

    patch receive_admin_purchase_path(purchase)
    assert purchase.reload.received?
    assert_equal stock_was + 25, products(:funda).reload.stock

    # Recibir dos veces no duplica stock.
    patch receive_admin_purchase_path(purchase)
    assert_equal stock_was + 25, products(:funda).reload.stock

    patch unreceive_admin_purchase_path(purchase)
    assert_not purchase.reload.received?
    assert_equal stock_was, products(:funda).reload.stock
  end

  test "el coste real medio pondera solo las compras recibidas" do
    purchase_with_line(quantity: 10, unit_cost: "2.00", shipping: "10").receive! # 3,00 €/ud.
    purchase_with_line(quantity: 30, unit_cost: "1.00", shipping: "0")           # pendiente: no cuenta
    costs = Purchase.average_landed_costs
    assert_equal 1, costs.size
    assert_equal 10, costs[products(:funda)][:units]
    assert_equal BigDecimal("3"), costs[products(:funda)][:avg_cost]

    get admin_purchases_path
    assert_response :success
    assert_includes response.body, "Coste real por producto"
  end

  test "una compra recibida no se puede borrar sin deshacer la recepción" do
    purchase = purchase_with_line(quantity: 5)
    purchase.receive!
    assert_no_difference "Purchase.count" do
      delete admin_purchase_path(purchase)
    end
    patch unreceive_admin_purchase_path(purchase)
    assert_difference "Purchase.count", -1 do
      delete admin_purchase_path(purchase)
    end
  end

  private

  def purchase_with_line(quantity:, unit_cost: "2.00", shipping: "0")
    purchase = Purchase.create!(supplier: @supplier, ordered_on: Date.current)
    purchase.purchase_lines.create!(product: products(:funda), quantity: quantity, unit_cost: unit_cost, shipping_cost: shipping)
    purchase
  end
end
