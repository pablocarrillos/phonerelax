module Admin
  class SuppliersController < BaseController
    before_action :set_supplier, only: [ :edit, :update, :destroy ]

    def index
      @suppliers = Supplier.ordered
    end

    def new
      @supplier = Supplier.new
    end

    def create
      @supplier = Supplier.new(supplier_params)
      if @supplier.save
        redirect_to admin_suppliers_path, notice: "Proveedor creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @supplier.update(supplier_params)
        redirect_to admin_suppliers_path, notice: "Proveedor actualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @supplier.destroy
        redirect_to admin_suppliers_path, notice: "Proveedor borrado."
      else
        redirect_to admin_suppliers_path, alert: @supplier.errors.full_messages.to_sentence
      end
    end

    private

    def set_supplier
      @supplier = Supplier.find(params[:id])
    end

    def supplier_params
      params.require(:supplier).permit(:name, :tax_id, :email, :phone, :website, :address, :country, :notes)
    end
  end
end
