# Recibe los eventos de Stripe. checkout.session.completed marca el pedido como pagado.
class StripeWebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    signature = request.env["HTTP_STRIPE_SIGNATURE"]
    event = Stripe::Webhook.construct_event(payload, signature, ENV.fetch("STRIPE_WEBHOOK_SECRET"))

    if event.type == "checkout.session.completed"
      checkout = event.data.object
      order = Order.find_by(stripe_session_id: checkout.id)
      # Respaldo: si el update! que guarda stripe_session_id falló o aún no se
      # había escrito, el pedido se localiza por el número que viaja en
      # client_reference_id (lo enviamos siempre al crear la sesión).
      order ||= Order.find_by(number: checkout.client_reference_id) if checkout.client_reference_id.present?
      order&.mark_paid!
    end
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end
end
