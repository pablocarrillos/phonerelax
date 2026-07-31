class ShopController < ApplicationController
  allow_unauthenticated_access

  def home
    @products = Product.active.ordered
  end

  def product
    @product = Product.active.find(params[:id])
  end
end
