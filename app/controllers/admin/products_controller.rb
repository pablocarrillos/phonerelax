module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [ :edit, :update, :destroy ]

    def index
      @products = Product.ordered
    end

    def new
      @product = Product.new(active: true)
      build_blank_tiers
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_products_path, notice: "Producto creado."
      else
        build_blank_tiers
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_blank_tiers
    end

    def update
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Producto actualizado."
      else
        build_blank_tiers
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

    # Huecos para añadir tramos de escalado nuevos desde el formulario.
    def build_blank_tiers
      2.times { @product.price_tiers.build }
    end

    def set_product
      @product = Product.find_by_param!(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :name_pt, :description_pt, :name_en, :description_en, :price, :cover_image, :active, :position, :stock, :vat_percentage, :auto_carousel,
                                      price_tiers_attributes: [ :id, :min_units, :unit_price, :_destroy ])
    end
  end
end
