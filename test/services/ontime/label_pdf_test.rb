require "test_helper"

module Ontime
  class LabelPdfTest < ActiveSupport::TestCase
    test "avisa si el envío no tiene etiqueta (ZPL vacío)" do
      fake = Object.new
      def fake.label_zpl(**) = ""
      err = assert_raises(Ontime::LabelPdf::Error) do
        Ontime::LabelPdf.new(fake).render(tracking: "X", postal_code: "03600")
      end
      assert_match(/no tiene etiqueta/i, err.message)
    end
  end
end
