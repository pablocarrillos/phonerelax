# Reenvía las solicitudes del formulario público de presupuesto al buzón de la tienda.
class QuoteMailer < ApplicationMailer
  RECIPIENT = ENV.fetch("CONTACT_EMAIL", "info@phonerelax.com")

  # `attrs`: hash con los campos del formulario (la solicitud no se persiste,
  # así que viaja como atributos planos serializables por ActiveJob).
  def new_request(attrs)
    @quote = attrs.symbolize_keys
    mail(to: RECIPIENT, reply_to: @quote[:email],
         subject: "Presupuesto web: #{@quote[:organization]} (#{@quote[:name]})")
  end
end
