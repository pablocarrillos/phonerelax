require "test_helper"

# El formulario de presupuesto no guarda nada: valida y reenvía la solicitud
# por email al buzón de la tienda, con antibots (honeypot, timestamp, rate limit).
class QuoteRequestFlowTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup do
    @timestamp_was = InvisibleCaptcha.timestamp_enabled
    @spinner_was = InvisibleCaptcha.spinner_enabled
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false
    Rails.cache.clear # reinicia el contador del rate limit entre tests
  end

  teardown do
    InvisibleCaptcha.timestamp_enabled = @timestamp_was
    InvisibleCaptcha.spinner_enabled = @spinner_was
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

  test "una solicitud válida se reenvía a la tienda con reply-to y no se guarda" do
    assert_no_difference "QuoteRequest.count" do
      assert_emails 1 do
        post quotes_path, params: { quote_request: valid_request }
      end
    end
    assert_redirected_to quote_path
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "info@phonerelax.com" ], mail.to
    assert_equal [ "ana@ies.es" ], mail.reply_to
    assert_includes mail.subject, "IES Sant Jordi"
    assert_includes mail.body.decoded, "Presupuesto para 4 aulas"
  end

  test "una solicitud inválida no envía email" do
    assert_emails 0 do
      post quotes_path, params: { quote_request: { name: "", organization: "", email: "no", message: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "el honeypot bloquea a los bots" do
    assert_emails 0 do
      post quotes_path,
           params: { quote_request: valid_request, InvisibleCaptcha.honeypots.first => "http://spam.example" }
    end
    assert_redirected_to quote_path
  end

  test "más de 5 envíos por hora desde la misma IP se bloquean" do
    assert_emails 5 do
      6.times { post quotes_path, params: { quote_request: valid_request } }
    end
    assert_redirected_to quote_path
  end

  private

  def valid_request
    { name: "Ana", organization: "IES Sant Jordi", email: "ana@ies.es",
      sector: "colegio", units: 120, message: "Presupuesto para 4 aulas" }
  end
end
