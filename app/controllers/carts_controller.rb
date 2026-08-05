class CartsController < ApplicationController
  allow_unauthenticated_access

  def show
    @lines = cart_lines
    @total = @lines.sum { |product, quantity| product.price_for_quantity(quantity) * quantity }
  end

  def add
    product = Product.active.find_by_param!(params[:product_id])
    return redirect_back(fallback_location: root_path, alert: "#{product.name} está agotado.") if product.out_of_stock?

    quantity = [ params[:quantity].to_i, 1 ].max
    wanted = (cart[product.id.to_s] || 0) + quantity
    cart[product.id.to_s] = [ wanted, product.available_stock ].min
    if wanted > product.available_stock
      redirect_to cart_path, alert: "Solo quedan #{product.available_stock} unidades de #{product.name}; hemos ajustado la cantidad."
    else
      redirect_to cart_path, notice: t("flash.added_to_cart", name: product.display_name)
    end
  end

  def update_quantity
    product = Product.find_by_param!(params[:product_id])
    quantity = params[:quantity].to_i
    if quantity.positive?
      capped = [ quantity, product.available_stock ].min
      cart[product.id.to_s] = capped
      return redirect_to cart_path, alert: "Solo quedan #{product.available_stock} unidades de #{product.name}." if capped < quantity
    else
      cart.delete(product.id.to_s)
    end
    redirect_to cart_path
  end

  def remove
    product = Product.find_by_param(params[:product_id])
    cart.delete(product.id.to_s) if product
    redirect_to cart_path
  end

  private

  def cart_lines
    products = Product.where(id: cart.keys).index_by { |p| p.id.to_s }
    cart.filter_map { |id, quantity| [ products[id], quantity ] if products[id] }
  end
end
