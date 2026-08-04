module Admin
  class ProductImagesController < BaseController
    before_action :set_product

    # Sube una o varias imágenes a la galería (ficheros, como la portada).
    def create
      files = Array(params[:files]).reject(&:blank?)
      if files.none?
        return redirect_to edit_admin_product_path(@product), alert: "Elige una o varias imágenes."
      end

      position = @product.product_images.maximum(:position) || 0
      files.each { |file| @product.product_images.create!(file: file, position: (position += 1)) }
      redirect_to edit_admin_product_path(@product),
                  notice: files.size == 1 ? "Imagen añadida." : "#{files.size} imágenes añadidas."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to edit_admin_product_path(@product), alert: e.record.errors.full_messages.to_sentence
    end

    # Intercambia la imagen con su vecina (direction: up/down) y renumera posiciones.
    def move
      images = @product.product_images.ordered.to_a
      index = images.index { |image| image.id == params[:id].to_i }
      target = params[:direction] == "up" ? index - 1 : index + 1
      if index && target.between?(0, images.size - 1)
        images[index], images[target] = images[target], images[index]
        images.each_with_index { |image, position| image.update_columns(position: position + 1) }
      end
      redirect_to edit_admin_product_path(@product)
    end

    def destroy
      @product.product_images.find(params[:id]).destroy
      redirect_to edit_admin_product_path(@product), notice: "Imagen quitada."
    end

    private

    def set_product
      @product = Product.find_by_param!(params[:product_id])
    end
  end
end
