require "test_helper"

# Muestras enviadas a posibles clientes: registro, coste y devolución.
class AdminSamplesTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "alta de una muestra con productos y coste calculado" do
    post admin_samples_path, params: { sample: {
      organization: "IES Cañada Real", contact_name: "Manuel Lorente", sent_on: "2026-08-01",
      sample_lines_attributes: {
        "0" => { product_id: products(:funda).id, quantity: 2 },
        "1" => { product_id: "" }
      }
    } }
    assert_redirected_to admin_samples_path
    sample = Sample.last
    assert_equal 1, sample.sample_lines.count
    # Sin compras registradas, el coste es el PVP sin IVA: 2 × (9,95 / 1,21).
    assert_in_delta 16.45, sample.cost.to_f, 0.01
    assert_not sample.returned?
  end

  test "marcar una muestra como devuelta" do
    sample = Sample.create!(organization: "Norfolk", sent_on: Date.current - 30)
    patch mark_returned_admin_sample_path(sample)
    assert_redirected_to admin_samples_path
    assert_equal Date.current, sample.reload.returned_on
  end

  test "el listado muestra los totales y el estado" do
    Sample.create!(organization: "Colegio Fuera", sent_on: Date.current - 10)
    devuelta = Sample.create!(organization: "Colegio Devuelto", sent_on: Date.current - 60, returned_on: Date.current - 5)
    devuelta.sample_lines.create!(product: products(:funda), quantity: 1)
    get admin_samples_path
    assert_response :success
    assert_select "h1", "Muestras enviadas"
    assert_includes response.body, "Colegio Fuera"
    assert_includes response.body, "Coste total de todas las muestras"
  end

  test "el coste usa el coste real medio de compras cuando existe" do
    supplier = Supplier.create!(name: "Fábrica")
    purchase = Purchase.create!(supplier: supplier, ordered_on: Date.current, shipping_cost: 10)
    purchase.purchase_lines.create!(product: products(:funda), quantity: 10, unit_cost: BigDecimal("2"))
    purchase.receive! # coste real: 3,00 €/ud.
    sample = Sample.create!(organization: "Colegio X", sent_on: Date.current)
    sample.sample_lines.create!(product: products(:funda), quantity: 4)
    assert_equal BigDecimal("12"), sample.cost(Purchase.average_landed_costs)
  end
end
