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

  # Aviso interno al almacén (en español) de un presupuesto aprobado: dirección
  # de envío, artículos y la etiqueta A5 adjunta. Se dispara con un botón desde
  # la ficha del presupuesto. Reutiliza los destinatarios del aviso de pedidos.
  def shipping_request(quote)
    @quote = quote
    attachments["etiqueta-#{quote.number}.pdf"] = ShippingLabelPdf.render(quote)
    mail(to: OrderMailer::SHIPPING_RECIPIENTS, cc: OrderMailer::SHIPPING_CC,
         subject: "Envío Presupuesto PHONE RELAX #{quote.number}")
  end
end
