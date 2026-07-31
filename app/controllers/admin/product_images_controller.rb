module Admin
  class ProductImagesController < BaseController
    before_action :set_product

    def create
      image = @product.product_images.new(url: params[:url].to_s.strip,
                                          position: (@product.product_images.maximum(:position) || 0) + 1)
      if image.save
        redirect_to edit_admin_product_path(@product), notice: 'Imagen añadida.'
      else
        redirect_to edit_admin_product_path(@product), alert: image.errors.full_messages.to_sentence
      end
    end

    def destroy
      @product.product_images.find(params[:id]).destroy
      redirect_to edit_admin_product_path(@product), notice: 'Imagen quitada.'
    end

    private

    def set_product
      @product = Product.find(params[:product_id])
    end
  end
end
