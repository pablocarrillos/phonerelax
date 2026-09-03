require "test_helper"

# Albaranes numerados (prefijo configurable en Datos de Empresa): desde un pedido o
# un presupuesto, sin precios, consumen número correlativo y se pueden editar
# después de emitirse manteniendo el número.
class DeliveryNotesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @setting = CompanySetting.current
    @product = Product.create!(name: "Bolsa test", price: 12.10, stock: 100, vat_percentage: 21, active: true)
    @order = Order.create!(customer_name: "Ana Test", email: "ana@example.com", phone: "612345678",
                           address: "C 1", city: "Elda", postal_code: "03600", province: "Alicante",
                           country: "España", payment_status: :pagado, total: 24.90, shipping_cost: 0.70)
    @order.order_lines.create!(product: @product, quantity: 2, unit_price: 12.10)

    @client = Client.create!(name: "Colegio Test", tax_id: "B00000000", address: "Calle 1", email: "cole@example.com")
    @quote = Quote.create!(client: @client, issued_on: Date.current, delivery_terms: "x", shipping_cost: 0, payment_terms: "x",
                           quote_lines_attributes: { "0" => { description: "Bolsas", quantity: 10, unit_price: "10", vat_rate: 21 } })
  end

  test "la serie de albaranes arranca en el 000032 y avanza sin reiniciar por año" do
    assert_equal "PHONERELAX-000032", @setting.take_delivery_note_number!
    assert_equal "PHONERELAX-000033", @setting.take_delivery_note_number!
    assert_equal 34, @setting.reload.delivery_note_next_number
  end

  test "el prefijo de los albaranes se cambia desde Datos de Empresa" do
    patch admin_company_setting_path, params: { company_setting: { delivery_note_series: "ALB", delivery_note_next_number: 50 } }
    assert_equal "ALB-000050", @setting.reload.take_delivery_note_number!
  end

  test "generar el albarán de un pedido copia cliente y líneas sin precios y avanza la serie" do
    assert_difference -> { DeliveryNote.count }, 1 do
      post admin_delivery_notes_path, params: { order_id: @order.id }
    end
    note = DeliveryNote.last
    assert_redirected_to edit_admin_delivery_note_path(note)

    assert_equal "PHONERELAX-000032", note.number
    assert_equal 33, @setting.reload.delivery_note_next_number, "la serie avanza al generar"
    assert_equal "Ana Test", note.client_name
    line = note.lines.sole
    assert_equal "Bolsa test", line.description
    assert_equal 2, line.quantity
    assert_not line.respond_to?(:unit_price), "las líneas del albarán no llevan precio"

    # repetir no crea otro albarán ni consume número: va al que ya existe
    assert_no_difference -> { DeliveryNote.count } do
      post admin_delivery_notes_path, params: { order_id: @order.id }
    end
    assert_redirected_to edit_admin_delivery_note_path(note)
    assert_equal 33, @setting.reload.delivery_note_next_number
  end

  test "generar el albarán de un presupuesto usa la misma serie" do
    post admin_delivery_notes_path, params: { order_id: @order.id }
    assert_difference -> { DeliveryNote.count }, 1 do
      post admin_delivery_notes_path, params: { quote_id: @quote.id }
    end
    note = @quote.reload.delivery_note
    assert_equal "PHONERELAX-000033", note.number, "pedidos y presupuestos comparten la serie"
    assert_equal "Colegio Test", note.client_name
    assert_equal "Calle 1", note.client_address, "los datos fiscales del cliente van en su bloque"
    assert_equal [ "Bolsas" ], note.lines.map(&:description)
  end

  test "el albarán emitido se puede editar (líneas y comentarios) pero el número no cambia" do
    note = DeliveryNote.issue_for_quote!(@quote)
    original_number = note.number
    line = note.lines.sole

    patch admin_delivery_note_path(note), params: { delivery_note: {
      number: "HACKED-0001", client_name: "Colegio Editado",
      comments: "Entregar en conserjería",
      lines_attributes: {
        "0" => { id: line.id, description: "Bolsas grandes", quantity: 8 },
        "1" => { description: "Muestras", quantity: 1, position: 1 },
        "2" => { description: "", quantity: 1 } # fila en blanco: se ignora
      }
    } }
    assert_redirected_to edit_admin_delivery_note_path(note)

    note.reload
    assert_equal original_number, note.number, "el número se mantiene aunque se intente cambiar"
    assert_equal "Colegio Editado", note.client_name
    assert_equal "Entregar en conserjería", note.comments
    assert_equal [ "Bolsas grandes", "Muestras" ], note.lines.map(&:description)

    # y se puede quitar una línea
    patch admin_delivery_note_path(note), params: { delivery_note: {
      lines_attributes: { "0" => { id: note.lines.last.id, _destroy: "1" } }
    } }
    assert_equal [ "Bolsas grandes" ], note.reload.lines.map(&:description)
  end

  test "el albarán del presupuesto lleva la dirección de entrega aparte" do
    @quote.update!(delivery_address: "Colegio Test, C/ Entrega 9, 03600 Elda")
    note = DeliveryNote.issue_for_quote!(@quote)

    assert_equal "Calle 1", note.client_address
    assert_equal "Colegio Test, C/ Entrega 9, 03600 Elda", note.delivery_address
    assert_equal note.delivery_address, note.pdf_data[:delivery_address]

    get pdf_admin_delivery_note_path(note)
    assert_response :success, "el PDF se genera con ambas direcciones"
  end

  test "el PDF del albarán se genera y no incluye importes" do
    note = DeliveryNote.issue_for_order!(@order)
    note.update!(comments: "Frágil")

    get pdf_admin_delivery_note_path(note)
    assert_response :success
    assert response.body.start_with?("%PDF"), "devuelve un PDF"
    assert_nil note.pdf_data[:lines].first[:unit_price], "los datos del PDF no llevan precios"
    assert_nil note.pdf_data[:total]
  end
end
