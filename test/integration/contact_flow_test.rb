require "test_helper"

# El formulario de contacto no guarda nada: valida y reenvía el mensaje por
# email al buzón de la tienda, con antibots (honeypot, timestamp, rate limit).
class ContactFlowTest < ActionDispatch::IntegrationTest
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

  test "reenvía el mensaje a la tienda con reply-to del remitente y no guarda nada" do
    assert_no_difference "ContactMessage.count" do
      assert_emails 1 do
        post contact_messages_path, params: { contact_message: valid_message }
      end
    end
    assert_redirected_to contacto_path
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ "phonerelaxstore@gmail.com" ], mail.to
    assert_equal [ "ana@example.com" ], mail.reply_to
    assert_includes mail.subject, "Ana"
    assert_includes mail.body.decoded, "Quiero 30 bolsas para mi academia"
  end

  test "un mensaje inválido no envía email" do
    assert_emails 0 do
      post contact_messages_path, params: { contact_message: valid_message.merge(email: "no-es-un-email") }
    end
    assert_response :unprocessable_entity
  end

  test "el honeypot bloquea a los bots" do
    assert_emails 0 do
      post contact_messages_path,
           params: { contact_message: valid_message, InvisibleCaptcha.honeypots.first => "http://spam.example" }
    end
    assert_redirected_to contacto_path
  end

  test "un envío sin haber cargado el formulario (timestamp) se rechaza" do
    InvisibleCaptcha.timestamp_enabled = true
    assert_emails 0 do
      post contact_messages_path, params: { contact_message: valid_message }
    end
    assert_redirected_to contacto_path
  end

  test "más de 5 envíos por hora desde la misma IP se bloquean" do
    assert_emails 5 do
      6.times { post contact_messages_path, params: { contact_message: valid_message } }
    end
    assert_redirected_to contacto_path
  end

  private

  def valid_message
    { name: "Ana Prueba", email: "ana@example.com", phone: "612345678",
      message: "Quiero 30 bolsas para mi academia" }
  end
end
