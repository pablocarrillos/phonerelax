class ShopController < ApplicationController
  allow_unauthenticated_access

  def home
    @products = Product.active.ordered
    @posts = Post.recent_first.limit(3)
  end

  def product
    @product = Product.active.find(params[:id])
  end
end
