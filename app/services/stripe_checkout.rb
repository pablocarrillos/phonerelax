# Sesiones del Checkout alojado de Stripe para un pedido.
class StripeCheckout
  def initialize(order, success_url:, cancel_url:)
    @order = order
    @success_url = success_url
    @cancel_url = cancel_url
  end

  def create_session
    Stripe::Checkout::Session.create(
      mode: "payment",
      # Tarjeta (incluye Google Pay / Apple Pay como wallets), PayPal y Alipay.
      payment_method_types: %w[card paypal alipay],
      customer_email: @order.email,
      client_reference_id: @order.number,
      line_items: line_items,
      success_url: @success_url,
      cancel_url: @cancel_url
    )
  end

  # Líneas del Checkout: los productos más, si procede, el transporte.
  def line_items
    items = @order.order_lines.map do |line|
      {
        quantity: line.quantity,
        price_data: {
          currency: "eur",
          unit_amount: (line.unit_price * 100).to_i,
          product_data: { name: line.product.name }
        }
      }
    end
    if @order.shipping_cost.positive?
      items << { quantity: 1,
                 price_data: { currency: "eur", unit_amount: (@order.shipping_cost * 100).to_i,
                               product_data: { name: "Transporte" } } }
    end
    items
  end

  # Consulta en Stripe si la sesión del pedido está pagada (vuelta del Checkout).
  def self.paid?(order)
    return false if order.stripe_session_id.blank?

    Stripe::Checkout::Session.retrieve(order.stripe_session_id).payment_status == "paid"
  rescue Stripe::StripeError
    false
  end
end
