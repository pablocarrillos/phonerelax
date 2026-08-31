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
      # Sin payment_method_types: el Checkout ofrece los métodos activados en el
      # dashboard de Stripe (tarjeta con Google/Apple Pay y los que se activen).
      customer_email: @order.email,
      client_reference_id: @order.number,
      line_items: line_items,
      success_url: @success_url,
      cancel_url: @cancel_url
    )
  end

  # Líneas del Checkout: los productos más, si procede, el transporte. Con
  # cupón, el descuento se reparte entre las líneas para que el cobro cuadre
  # al céntimo con el total del pedido.
  def line_items
    amounts = discounted_line_amounts
    items = @order.order_lines.each_with_index.map do |line, index|
      name = line.product.name
      name += " (cupón #{@order.coupon_code})" if @order.coupon_discount.to_d.positive?
      # cantidad 1 con el importe total de la línea: el unitario con descuento
      # prorrateado no siempre da céntimos exactos por unidad
      {
        quantity: 1,
        price_data: {
          currency: "eur",
          unit_amount: amounts[index],
          product_data: { name: "#{name} × #{line.quantity}" }
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

  # Importe en céntimos de cada línea con el descuento del cupón prorrateado;
  # el redondeo sobrante se ajusta en la última línea.
  def discounted_line_amounts
    gross = @order.order_lines.map { |line| (line.unit_price * line.quantity * 100).round }
    discount = (@order.coupon_discount.to_d * 100).round
    return gross unless discount.positive? && gross.sum.positive?

    total = gross.sum
    discounts = gross.map { |cents| (discount * cents / total.to_d).floor }
    discounts[-1] += discount - discounts.sum
    gross.each_with_index.map { |cents, i| cents - discounts[i] }
  end

  # Consulta en Stripe si la sesión del pedido está pagada (vuelta del Checkout).
  def self.paid?(order)
    return false if order.stripe_session_id.blank?

    Stripe::Checkout::Session.retrieve(order.stripe_session_id).payment_status == "paid"
  rescue Stripe::StripeError
    false
  end
end
