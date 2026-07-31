class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend
  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :cart_items_count

  private

  # Carrito en sesión: { "product_id" => cantidad }
  def cart
    session[:cart] ||= {}
  end

  def cart_items_count
    cart.values.sum
  end
end
