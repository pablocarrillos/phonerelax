require "test_helper"

module Admin
  class OntimeShipmentsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as(users(:one)) }

    def order = orders(:uno)

    # minitest 6 no trae stub: redefinimos un método de Ontime::Client y lo
    # restauramos al terminar.
    def stubbing(method, impl)
      original = Ontime::Client.instance_method(method)
      Ontime::Client.send(:define_method, method, impl)
      yield
    ensure
      Ontime::Client.send(:define_method, method, original)
    end

    def valid_params(**overrides)
      { ontime_shipment: {
        shippable_type: "Order", shippable_id: order.id,
        name: "Cliente Uno", address: "Calle Mayor 1", city: "Madrid",
        postal_code: "28001", country_iso: "ES", phone: "600000001",
        service_code: "24", parcel_count: 1, weight: 1
      }.merge(overrides) }
    end

    test "la lista responde" do
      get admin_ontime_shipments_path
      assert_response :success
    end

    test "la pantalla de alta muestra el formulario prerrellenado" do
      get new_admin_ontime_shipment_path(shippable_type: "Order", shippable_id: order.id)
      assert_response :success
      assert_select "form[action=?]", admin_ontime_shipments_path
      assert_select "input[name=?][value=?]", "ontime_shipment[name]", "Cliente Uno"
    end

    test "alta con destinatario desconocido redirige a la lista" do
      get new_admin_ontime_shipment_path(shippable_type: "Order", shippable_id: 0)
      assert_redirected_to admin_ontime_shipments_path
    end

    test "crea el envío en Ontime, lo guarda y lo apunta en el historial" do
      stubbing(:create_shipment, ->(_payload) { { "trackingNumber" => "000322TEST01" } }) do
        assert_difference -> { order.ontime_shipments.count } => 1,
                          -> { order.order_events.count } => 1 do
          post admin_ontime_shipments_path, params: valid_params
        end
      end
      assert_redirected_to admin_order_path(order)
      shipment = order.ontime_shipments.order(:id).last
      assert_equal "000322TEST01", shipment.tracking_number
      assert_equal "28001", shipment.postal_code
    end

    test "no crea el envío si faltan datos del destinatario" do
      assert_no_difference -> { OntimeShipment.count } do
        post admin_ontime_shipments_path, params: valid_params(postal_code: "")
      end
      assert_response :unprocessable_entity
    end

    test "si Ontime rechaza el envío, avisa y no lo guarda" do
      stubbing(:create_shipment, ->(_payload) { raise Ontime::Client::Error, "TMS lo rechazó" }) do
        assert_no_difference -> { OntimeShipment.count } do
          post admin_ontime_shipments_path, params: valid_params
        end
      end
      assert_response :unprocessable_entity
      assert_match(/no se pudo crear/i, response.body)
    end

    test "poll consulta el estado y redirige" do
      shipment = order.ontime_shipments.create!(admission_code: "PRPOLL01", tracking_number: "000322POLL",
                                                postal_code: "28001", service_code: "24", last_response: {})
      body = { "success" => true, "currentStatus" => "En reparto", "events" => [] }
      stubbing(:tracking, ->(**_kw) { body }) do
        post poll_admin_ontime_shipment_path(shipment)
      end
      assert_response :redirect
      assert_equal "En reparto", shipment.reload.status
    end
  end
end
