class CartsController < ApplicationController
  allow_unauthenticated_access

  def show
    @lines = cart_lines
    @total = @lines.sum { |product, quantity| product.price * quantity }
  end

  def add
    product = Product.active.find(params[:product_id])
    return redirect_back(fallback_location: root_path, alert: "#{product.name} está agotado.") if product.out_of_stock?

    quantity = [params[:quantity].to_i, 1].max
    wanted = (cart[product.id.to_s] || 0) + quantity
    cart[product.id.to_s] = [wanted, product.stock].min
    if wanted > product.stock
      redirect_to cart_path, alert: "Solo quedan #{product.stock} unidades de #{product.name}; hemos ajustado la cantidad."
    else
      redirect_to cart_path, notice: "#{product.name} añadido al carrito."
    end
  end

  def update_quantity
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i
    if quantity.positive?
      capped = [quantity, product.stock].min
      cart[product.id.to_s] = capped
      return redirect_to cart_path, alert: "Solo quedan #{product.stock} unidades de #{product.name}." if capped < quantity
    else
      cart.delete(product.id.to_s)
    end
    redirect_to cart_path
  end

  def remove
    cart.delete(params[:product_id].to_s)
    redirect_to cart_path
  end

  private

  def cart_lines
    products = Product.where(id: cart.keys).index_by { |p| p.id.to_s }
    cart.filter_map { |id, quantity| [products[id], quantity] if products[id] }
  end
end
