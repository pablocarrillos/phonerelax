require "test_helper"

module Ontime
  class ShipmentBuilderTest < ActiveSupport::TestCase
    def recipient
      { name: "Juan Pérez", address: "C/ Mayor 3", city: "Elda",
        postal_code: "03600", country_iso: "ES", phone: "600123123", email: "j@x.es" }
    end

    test "monta el payload con los campos obligatorios de Ontime" do
      payload = ShipmentBuilder.build(recipient: recipient, admission_code: "PRTEST01")

      assert_equal "PRTEST01", payload["admissionCode"]
      assert_equal "000322", payload["originCenter"]
      assert_equal "24", payload["productCode"]
      assert_equal Date.current.iso8601, payload["delayedDeliveryDate"]
      assert_equal true, payload["finalShipment"]
      assert_equal "ZPL", payload["labelFormat"]
    end

    test "mapea el destinatario a los nombres de campo de Ontime" do
      r = ShipmentBuilder.build(recipient: recipient, admission_code: "X")["recipient"]

      assert_equal "Juan Pérez", r["name"]
      assert_equal "Juan Pérez", r["contactName"]
      assert_equal "03600", r["postalCode"]
      assert_equal "ES", r["country"]
    end

    test "el remitente lleva el NIF de Phone Relax" do
      sender = ShipmentBuilder.build(recipient: recipient, admission_code: "X")["sender"]
      assert_equal "B02631976", sender["taxId"]
      assert_equal "ES", sender["country"]
    end

    test "normaliza bultos y peso" do
      payload = ShipmentBuilder.build(recipient: recipient, admission_code: "X", parcel_count: 0, weight: 0)
      assert_equal 1, payload["parcelCount"]
      assert_equal 1.0, payload["weight"]
    end

    test "el servicio por defecto es 24 cuando llega en blanco" do
      payload = ShipmentBuilder.build(recipient: recipient, admission_code: "X", service_code: "")
      assert_equal "24", payload["productCode"]
    end

    test "el centro de origen es configurable por ENV" do
      original = ENV["ONTIME_ORIGIN_CENTER"]
      ENV["ONTIME_ORIGIN_CENTER"] = "000999"
      payload = ShipmentBuilder.build(recipient: recipient, admission_code: "X")
      assert_equal "000999", payload["originCenter"]
    ensure
      original ? ENV["ONTIME_ORIGIN_CENTER"] = original : ENV.delete("ONTIME_ORIGIN_CENTER")
    end
  end
end
