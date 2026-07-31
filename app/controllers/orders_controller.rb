class OrdersController < ApplicationController
  allow_unauthenticated_access

  # Formulario de datos del cliente con el resumen del carrito.
  def new
    @lines = cart_lines
    redirect_to cart_path, alert: 'El carrito está vacío.' if @lines.empty?
    @total = @lines.sum { |product, quantity| product.price * quantity }
    @order = Order.new
  end

  # Crea el pedido desde el carrito y envía al cliente al Checkout de Stripe.
  def create
    lines = cart_lines
    return redirect_to(cart_path, alert: 'El carrito está vacío.') if lines.empty?

    @order = Order.new(order_params)
    lines.each do |product, quantity|
      @order.order_lines.build(product: product, quantity: quantity, unit_price: product.price)
    end
    @order.total = @order.compute_total

    unless @order.save
      @lines = lines
      @total = @order.total
      return render :new, status: :unprocessable_entity
    end

    checkout = StripeCheckout.new(@order, success_url: order_success_url(@order.number),
                                          cancel_url: order_cancel_url(@order.number)).create_session
    @order.update!(stripe_session_id: checkout.id)
    session[:cart] = {}
    redirect_to checkout.url, allow_other_host: true
  rescue Stripe::StripeError => e
    @order&.destroy if @order&.persisted? && @order.pago_pendiente?
    redirect_to cart_path, alert: "No se pudo iniciar el pago: #{e.message}"
  end

  # Vuelta del Checkout: confirmamos contra Stripe (el webhook es la fuente definitiva).
  def success
    @order = Order.find_by!(number: params[:number])
    @order.mark_paid! if !@order.pago_pagado? && StripeCheckout.paid?(@order)
    redirect_to order_status_path(@order.number)
  end

  def cancel
    @order = Order.find_by!(number: params[:number])
    flash[:alert] = 'Pago cancelado. Puedes intentarlo de nuevo cuando quieras.'
    redirect_to order_status_path(@order.number)
  end

  # Página de estado del pedido para el cliente (enlace con su número).
  def show
    @order = Order.includes(order_lines: :product).find_by!(number: params[:number])
  end

  private

  def order_params
    params.require(:order).permit(:customer_name, :email, :phone, :address)
  end

  def cart_lines
    products = Product.active.where(id: cart.keys).index_by { |p| p.id.to_s }
    cart.filter_map { |id, quantity| [products[id], quantity] if products[id] }
  end
end
