# Recibe los eventos de Stripe. checkout.session.completed marca el pedido como pagado.
class StripeWebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    signature = request.env["HTTP_STRIPE_SIGNATURE"]
    event = Stripe::Webhook.construct_event(payload, signature, ENV.fetch("STRIPE_WEBHOOK_SECRET"))

    if event.type == "checkout.session.completed"
      order = Order.find_by(stripe_session_id: event.data.object.id)
      order&.mark_paid!
    end
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end
end
