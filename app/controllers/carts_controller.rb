class CartsController < ApplicationController
  allow_unauthenticated_access

  def show
    @lines = cart_lines
    @total = @lines.sum { |product, quantity| product.price * quantity }
  end

  def add
    product = Product.active.find(params[:product_id])
    quantity = [params[:quantity].to_i, 1].max
    cart[product.id.to_s] = (cart[product.id.to_s] || 0) + quantity
    redirect_to cart_path, notice: "#{product.name} añadido al carrito."
  end

  def update_quantity
    quantity = params[:quantity].to_i
    if quantity.positive?
      cart[params[:product_id].to_s] = quantity
    else
      cart.delete(params[:product_id].to_s)
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
