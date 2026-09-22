require "test_helper"

module Ontime
  class ClientTest < ActiveSupport::TestCase
    # instancia de usar y tirar: le sobreescribimos el GET privado sin tocar la red
    def client_returning(response)
      Ontime::Client.new.tap { |c| c.define_singleton_method(:get) { |_path| response } }
    end

    test "label_zpl devuelve el contenido ZPL cuando Ontime responde ok" do
      client = client_returning("success" => true, "label" => { "content" => "^XA...^XZ" })
      assert_equal "^XA...^XZ", client.label_zpl(tracking: "X", postal_code: "03600")
    end

    test "label_zpl avisa si Ontime dice que no hay envío" do
      client = client_returning("success" => false, "message" => "SHIPMENT_NOT_FOUND")
      err = assert_raises(Ontime::Client::Error) { client.label_zpl(tracking: "X", postal_code: "03600") }
      assert_match(/SHIPMENT_NOT_FOUND/, err.message)
    end

    test "SHIPMENT_NOT_FOUND se traduce a un mensaje claro" do
      client = client_returning("success" => false, "errorCode" => "SHIPMENT_NOT_FOUND", "message" => "No shipment found")
      err = assert_raises(Ontime::Client::Error) { client.label_zpl(tracking: "X", postal_code: "03600") }
      assert_match(/No existe ning\u00fan env\u00edo/i, err.message)
    end

    # instancia que responde al POST privado sin tocar la red
    def client_posting(response)
      Ontime::Client.new.tap { |c| c.define_singleton_method(:post) { |_path, _payload| response } }
    end

    test "create_shipment devuelve el resultado con nº de seguimiento (forma plana)" do
      client = client_posting("success" => true, "trackingNumber" => "0003220179503760", "admissionCode" => "PRX")
      result = client.create_shipment({ "admissionCode" => "PRX" })
      assert_equal "0003220179503760", result["trackingNumber"]
    end

    test "create_shipment admite el resultado dentro de un array shipments" do
      client = client_posting("success" => true, "shipments" => [ { "trackingNumber" => "000322000001" } ])
      result = client.create_shipment({})
      assert_equal "000322000001", result["trackingNumber"]
    end

    test "create_shipment revienta si Ontime rechaza el envío" do
      client = client_posting("success" => false, "message" => "OK", "shipments" => [])
      err = assert_raises(Ontime::Client::Error) { client.create_shipment({}) }
      assert_match(/no aceptó el envío/i, err.message)
    end

    test "tracking devuelve el sobre completo tal cual" do
      body = { "success" => true, "currentStatus" => "En reparto", "events" => [] }
      client = client_returning(body)
      assert_equal body, client.tracking(tracking: "X", postal_code: "03600")
    end

    test "sin credenciales avisa claramente" do
      keys = %w[ONTIME_API_USER ONTIME_API_PASSWORD ONTIME_API_TOKEN]
      saved = keys.index_with { |k| ENV[k] }
      keys.each { |k| ENV.delete(k) }
      err = assert_raises(Ontime::Client::Error) { Ontime::Client.new.label_zpl(tracking: "X", postal_code: "03600") }
      assert_match(/faltan credenciales/i, err.message)
    ensure
      saved.each { |k, v| ENV[k] = v }
    end
  end
end
