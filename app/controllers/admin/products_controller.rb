module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [ :edit, :update, :destroy ]

    def index
      @products = Product.ordered
    end

    # Nuevo orden tras arrastrar en la lista: recibe los ids ordenados y
    # reasigna las posiciones 1..n en una transacción.
    def reorder
      ids = Array(params[:ids]).map(&:to_i)
      return head :unprocessable_entity if ids.empty?

      Product.transaction do
        ids.each_with_index { |id, index| Product.where(id: id).update_all(position: index + 1) }
      end
      head :ok
    end

    def new
      @product = Product.new(active: true)
      build_blank_rows
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_products_path, notice: "Producto creado."
      else
        build_blank_rows
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_blank_rows
    end

    def update
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Producto actualizado."
      else
        build_blank_rows
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @product.destroy
        redirect_to admin_products_path, notice: "Producto borrado."
      else
        redirect_to admin_products_path, alert: @product.errors.full_messages.to_sentence
      end
    end

    private

    # Huecos para añadir tramos de escalado y componentes de pack nuevos.
    def build_blank_rows
      2.times { @product.price_tiers.build }
      3.times { @product.pack_items.build }
    end

    def set_product
      @product = Product.find_by_param!(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :name_pt, :description_pt, :name_en, :description_en, :name_fr, :description_fr, :price, :cover_image, :active, :stock, :vat_percentage, :auto_carousel, :pack,
                                      price_tiers_attributes: [ :id, :min_units, :unit_price, :_destroy ],
                                      pack_items_attributes: [ :id, :component_id, :quantity, :position, :_destroy ])
    end
  end
end
