# Sesiones del Checkout alojado de Stripe para un pedido.
class StripeCheckout
  def initialize(order, success_url:, cancel_url:)
    @order = order
    @success_url = success_url
    @cancel_url = cancel_url
  end

  def create_session
    Stripe::Checkout::Session.create(
      mode: 'payment',
      customer_email: @order.email,
      client_reference_id: @order.number,
      line_items: @order.order_lines.map do |line|
        {
          quantity: line.quantity,
          price_data: {
            currency: 'eur',
            unit_amount: (line.unit_price * 100).to_i,
            product_data: { name: line.product.name }
          }
        }
      end,
      success_url: @success_url,
      cancel_url: @cancel_url
    )
  end

  # Consulta en Stripe si la sesión del pedido está pagada (vuelta del Checkout).
  def self.paid?(order)
    return false if order.stripe_session_id.blank?

    Stripe::Checkout::Session.retrieve(order.stripe_session_id).payment_status == 'paid'
  rescue Stripe::StripeError
    false
  end
end
