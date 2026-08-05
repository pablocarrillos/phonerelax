# Reenvía los mensajes del formulario público de contacto al buzón de la tienda.
class ContactMailer < ApplicationMailer
  RECIPIENT = ENV.fetch("CONTACT_EMAIL", "info@phonerelax.com")

  # `attrs`: hash con name, email, phone y message (el mensaje no se persiste,
  # así que viaja como atributos planos serializables por ActiveJob).
  def new_message(attrs)
    @contact = attrs.symbolize_keys
    mail(to: RECIPIENT, reply_to: @contact[:email],
         subject: "Contacto web: #{@contact[:name]}")
  end
end
