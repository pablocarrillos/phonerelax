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

    # Intercambia la imagen con su vecina (direction: up/down) y renumera posiciones.
    def move
      images = @product.product_images.ordered.to_a
      index = images.index { |image| image.id == params[:id].to_i }
      target = params[:direction] == 'up' ? index - 1 : index + 1
      if index && target.between?(0, images.size - 1)
        images[index], images[target] = images[target], images[index]
        images.each_with_index { |image, position| image.update_columns(position: position + 1) }
      end
      redirect_to edit_admin_product_path(@product)
    end

    def destroy
      @product.product_images.find(params[:id]).destroy
      redirect_to edit_admin_product_path(@product), notice: 'Imagen quitada.'
    end

    private

    def set_product
      @product = Product.find_by_param!(params[:product_id])
    end
  end
end
