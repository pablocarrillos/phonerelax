require "test_helper"

module Admin
  class OntimeLabelsControllerTest < ActionDispatch::IntegrationTest
    setup { sign_in_as(users(:one)) }

    # minitest 6 no trae stub: redefinimos Ontime::LabelPdf.render y restauramos.
    def stubbing_render(value_or_proc)
      original = Ontime::LabelPdf.method(:render)
      Ontime::LabelPdf.define_singleton_method(:render) do |**kwargs|
        value_or_proc.respond_to?(:call) ? value_or_proc.call(**kwargs) : value_or_proc
      end
      yield
    ensure
      Ontime::LabelPdf.define_singleton_method(:render, original)
    end

    test "la página muestra el formulario de etiqueta" do
      get admin_ontime_labels_path
      assert_response :success
      assert_select "form[action=?]", admin_ontime_label_pdf_path
    end

    test "con nº de seguimiento y CP devuelve la etiqueta en PDF" do
      stubbing_render("%PDF-1.4 test") do
        get admin_ontime_label_pdf_path(tracking: "0003220179503760", cp: "03600")
      end
      assert_response :success
      assert_equal "application/pdf", response.media_type
      assert response.body.start_with?("%PDF")
    end

    test "sin nº de seguimiento o CP avisa y no consulta a Ontime" do
      get admin_ontime_label_pdf_path(tracking: "", cp: "")
      assert_redirected_to admin_ontime_labels_path
      assert_match(/nº de seguimiento y el código postal/i, flash[:alert])
    end

    test "si Ontime falla, avisa sin reventar" do
      stubbing_render(->(**) { raise Ontime::Client::Error, "SHIPMENT_NOT_FOUND" }) do
        get admin_ontime_label_pdf_path(tracking: "X", cp: "03600")
      end
      assert_redirected_to admin_ontime_labels_path
      assert_match(/No se pudo obtener la etiqueta/i, flash[:alert])
    end
  end
end
