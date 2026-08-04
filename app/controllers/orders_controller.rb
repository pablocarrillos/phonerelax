class OrdersController < ApplicationController
  allow_unauthenticated_access
  # Protección antibots: honeypot + tiempo mínimo de envío.
  invisible_captcha only: [ :create ], on_spam: :spam_detected, on_timestamp_spam: :spam_detected

  # Formulario de datos del cliente con el resumen del carrito.
  def new
    @lines = cart_lines
    redirect_to cart_path, alert: t("flash.cart_empty") if @lines.empty?
    @total = @lines.sum { |product, quantity| product.price_for_quantity(quantity) * quantity }
    @order = Order.new
  end

  # Crea el pedido desde el carrito, calcula el transporte y muestra el paso de pago.
  def create
    lines = cart_lines
    return redirect_to(cart_path, alert: t("flash.cart_empty")) if lines.empty?

    # Última comprobación de stock antes de cobrar.
    without_stock = lines.select { |product, quantity| quantity > product.stock }
    if without_stock.any?
      names = without_stock.map { |product, _| product.name }.join(", ")
      return redirect_to(cart_path, alert: t("flash.out_of_stock", names: names))
    end

    @order = Order.new(order_params)
    @order.locale = I18n.locale # idioma en que el cliente completó la compra

    # Si pide factura con un NIF-IVA europeo, lo comprobamos en VIES en el
    # servidor (no nos fiamos del navegador) y guardamos el resultado.
    if @order.needs_invoice && @order.tax_id.present? && TaxId.eu_vat?(@order.tax_id)
      @order.vies_valid = Vies.check(@order.tax_id)[:valid]
    end
    @order.apply_vat_exemption! # fija vat_exempt (hoy siempre false salvo interruptor)

    lines.each do |product, quantity|
      # El precio unitario se congela con el escalado por cantidad aplicado; sin
      # IVA si la venta resulta exenta.
      unit_price = @order.vat_exempt? ? product.net_price_for_quantity(quantity) : product.price_for_quantity(quantity)
      @order.order_lines.build(product: product, quantity: quantity, unit_price: unit_price)
    end
    @order.total = @order.compute_total

    unless @order.save
      @lines = lines
      @total = @order.total
      return render :new, status: :unprocessable_entity
    end

    @order.update!(shipping_cost: @order.compute_shipping,
                   total: @order.compute_total + @order.compute_shipping)
    redirect_to order_pay_path(@order.number)
  end

  # Paso de pago: pedido con el transporte ya sumado y botón de Stripe.
  def pay_page
    @order = Order.includes(order_lines: :product).find_by!(number: params[:number])
    redirect_to order_status_path(@order.number) if @order.pago_pagado?
  end

  # Lanza el Checkout de Stripe para el pedido ya calculado.
  def pay
    @order = Order.find_by!(number: params[:number])
    return redirect_to(order_status_path(@order.number)) if @order.pago_pagado?

    checkout = StripeCheckout.new(@order, success_url: order_success_url(@order.number),
                                          cancel_url: order_cancel_url(@order.number)).create_session
    @order.update!(stripe_session_id: checkout.id)
    session[:cart] = {}
    redirect_to checkout.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to order_pay_path(@order.number), alert: t("flash.payment_start_failed", error: e.message)
  end

  # Vuelta del Checkout: confirmamos contra Stripe (el webhook es la fuente definitiva).
  def success
    @order = Order.find_by!(number: params[:number])
    @order.mark_paid! if !@order.pago_pagado? && StripeCheckout.paid?(@order)
    redirect_to order_status_path(@order.number)
  end

  def cancel
    @order = Order.find_by!(number: params[:number])
    flash[:alert] = t("flash.payment_cancelled")
    redirect_to order_pay_path(@order.number)
  end

  # Página de estado del pedido para el cliente (enlace con su número).
  def show
    @order = Order.includes(order_lines: :product).find_by!(number: params[:number])
  end

  private

  # Peticiones que no parecen humanas: de vuelta al carrito sin crear nada.
  def spam_detected
    redirect_to cart_path, alert: t("flash.verify_failed")
  end

  def order_params
    params.require(:order).permit(:customer_name, :email, :phone, :address, :city, :postal_code, :province, :country,
                                  :needs_invoice, :tax_name, :tax_id, :tax_address, :tax_city, :tax_postal_code,
                                  :tax_province, :tax_country)
  end

  def cart_lines
    products = Product.active.where(id: cart.keys).index_by { |p| p.id.to_s }
    cart.filter_map { |id, quantity| [ products[id], quantity ] if products[id] }
  end
end
