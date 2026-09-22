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
