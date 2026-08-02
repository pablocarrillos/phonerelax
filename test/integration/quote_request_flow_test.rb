require "test_helper"

class QuoteRequestFlowTest < ActionDispatch::IntegrationTest
  setup do
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false
  end
  teardown do
    InvisibleCaptcha.timestamp_enabled = true
    InvisibleCaptcha.spinner_enabled = true
  end

  test "la página de presupuesto se renderiza en los tres idiomas" do
    get quote_path
    assert_response :success
    assert_select "h1"
    get quote_path(locale: :pt)
    assert_response :success
    get quote_path(locale: :en)
    assert_response :success
  end

  test "una solicitud válida se guarda" do
    get quote_path # carga el formulario (inicializa la sesión antispam)
    assert_difference -> { QuoteRequest.count }, 1 do
      post quotes_path, params: { quote_request: {
        name: "Ana", organization: "IES Sant Jordi", email: "ana@ies.es",
        sector: "colegio", units: 120, message: "Presupuesto para 4 aulas"
      } }
    end
    assert_redirected_to quote_path
  end

  test "una solicitud inválida no se guarda" do
    get quote_path
    assert_no_difference -> { QuoteRequest.count } do
      post quotes_path, params: { quote_request: { name: "", organization: "", email: "no", message: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "el admin ve el listado de solicitudes" do
    QuoteRequest.create!(name: "Ana", organization: "IES X", email: "a@x.com", message: "m")
    sign_in_as(users(:one))
    get admin_quote_requests_path
    assert_response :success
    assert_select "h1", "Solicitudes de presupuesto"
  end
end
