class ShopController < ApplicationController
  allow_unauthenticated_access

  def home
    @products = Product.active.ordered
    @posts = Post.recent_first.limit(3)
  end

  def product
    # Busca por slug (handle) y, para no romper enlaces antiguos, por id numérico.
    @product = Product.active.find_by_param!(params[:id])

    # Redirige 301 de la URL antigua (/producto/1) a la canónica con slug.
    if params[:id] != @product.to_param
      redirect_to product_page_path(@product), status: :moved_permanently
    end
  end
end
