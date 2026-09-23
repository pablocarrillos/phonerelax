require "test_helper"

class OntimeShipmentTest < ActiveSupport::TestCase
  def order = orders(:uno)

  def build_shipment(**attrs)
    order.ontime_shipments.create!({
      admission_code: "PR#{SecureRandom.hex(4).upcase}",
      tracking_number: "0003220179503760",
      postal_code: "03600",
      service_code: "24",
      recipient_name: "Cliente Uno",
      last_response: {}
    }.merge(attrs))
  end

  # cliente falso que devuelve las respuestas de tracking en orden
  def fake_client(*responses)
    Object.new.tap do |c|
      c.instance_variable_set(:@r, responses)
      c.instance_variable_set(:@i, 0)
      def c.tracking(**)
        r = @r[@i] || @r.last
        @i += 1
        r
      end
    end
  end

  test "display_status nunca está vacío" do
    assert_equal "pendiente de recogida", build_shipment(status: nil).display_status
  end

  test "poll! actualiza el estado y apunta los eventos nuevos en el historial del pedido" do
    shipment = build_shipment
    before = order.order_events.count
    body = { "success" => true, "eventCount" => 2,
             "currentStatus" => { "description" => "En tránsito", "statusCode" => "TR" },
             "events" => [ { "date" => "2026-09-22", "description" => "Admitido" },
                           { "date" => "2026-09-22", "description" => "En tránsito" } ] }

    shipment.poll!(client: fake_client(body))

    assert_equal "En tránsito", shipment.reload.status
    assert_equal "TR", shipment.status_code
    assert_equal 2, shipment.event_count
    assert_equal before + 2, order.order_events.count
    assert_match(/Admitido/, order.order_events.chronological.to_a[-2].event)
  end

  test "poll! solo apunta los eventos nuevos entre consultas" do
    shipment = build_shipment
    first = { "success" => true, "eventCount" => 1, "currentStatus" => "Admitido",
              "events" => [ { "description" => "Admitido" } ] }
    second = { "success" => true, "eventCount" => 2, "currentStatus" => "Entregado",
               "events" => [ { "description" => "Admitido" }, { "description" => "Entregado" } ] }
    client = fake_client(first, second)

    before = order.order_events.count
    shipment.poll!(client: client)
    shipment.poll!(client: client)

    assert_equal before + 2, order.order_events.count # 1 + 1, no repite "Admitido"
    assert shipment.reload.delivered
  end

  test "poll! marca entregado cuando el estado lo indica" do
    shipment = build_shipment
    body = { "success" => true, "currentStatus" => "Entregado al destinatario", "events" => [] }
    shipment.poll!(client: fake_client(body))
    assert shipment.reload.delivered
  end

  test "poll! no revienta si Ontime no encuentra el envío" do
    shipment = build_shipment
    body = { "success" => false, "errorCode" => "SHIPMENT_NOT_FOUND" }
    assert_nothing_raised { shipment.poll!(client: fake_client(body)) }
    assert_nil shipment.reload.status
  end

  test "poll! no hace nada sin nº de seguimiento" do
    shipment = build_shipment(tracking_number: nil)
    called = false
    client = Object.new.tap { |c| c.define_singleton_method(:tracking) { |**| called = true; {} } }
    shipment.poll!(client: client)
    assert_not called
  end

  test "trackable excluye entregados y sin seguimiento" do
    active = build_shipment
    build_shipment(delivered: true)
    build_shipment(tracking_number: nil)
    assert_includes OntimeShipment.trackable, active
    assert_equal 1, OntimeShipment.trackable.count
  end

  test "delivered_status? reconoce variantes de entrega" do
    assert OntimeShipment.delivered_status?("ENTREGADO")
    assert OntimeShipment.delivered_status?("Delivered")
    assert_not OntimeShipment.delivered_status?("En tránsito")
  end

  test "interpreta el esquema real de Ontime (statusName/statusCode)" do
    ontime_status = { "date" => "2026-09-22T16:05:35", "statusCode" => 0, "statusName" => "Documentado" }
    assert_equal "Documentado", OntimeShipment.status_text(ontime_status)
    assert_equal "22/09/2026 16:05 · Documentado", OntimeShipment.event_text(ontime_status)
    assert_equal 0, OntimeShipment.status_code_from(ontime_status)
  end

  test "poll! muestra el nombre del estado y registra el evento con fecha legible" do
    shipment = build_shipment
    body = { "success" => true, "eventCount" => 1,
             "events" => [ { "date" => "2026-09-22T16:05:35", "statusCode" => 0, "statusName" => "Documentado" } ] }
    shipment.poll!(client: fake_client(body))
    assert_equal "Documentado", shipment.reload.status
    assert_match(/Documentado/, order.order_events.chronological.last.event)
  end
end
