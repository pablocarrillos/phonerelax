module Admin
  class PurchasesController < BaseController
    before_action :set_purchase, only: [ :show, :edit, :update, :destroy, :receive, :unreceive ]

    def index
      @purchases = Purchase.includes(:supplier, purchase_lines: :product).recent_first
      @landed_costs = Purchase.average_landed_costs
    end

    def show; end

    def new
      @purchase = Purchase.new(ordered_on: Date.current)
      build_blank_lines
    end

    def create
      @purchase = Purchase.new(purchase_params)
      if @purchase.save
        redirect_to admin_purchase_path(@purchase), notice: "Compra registrada."
      else
        build_blank_lines
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_blank_lines
    end

    def update
      if @purchase.update(purchase_params)
        redirect_to admin_purchase_path(@purchase), notice: "Compra actualizada."
      else
        build_blank_lines
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @purchase.received?
        redirect_to admin_purchase_path(@purchase), alert: "Deshaz antes la recepción (el stock ya se sumó)."
      else
        @purchase.destroy!
        redirect_to admin_purchases_path, notice: "Compra borrada."
      end
    end

    # Marca la compra como recibida: suma las unidades al stock.
    def receive
      @purchase.receive!
      redirect_to admin_purchase_path(@purchase), notice: "Compra recibida: stock actualizado."
    end

    # Deshace una recepción marcada por error, restando el stock sumado.
    def unreceive
      @purchase.unreceive!
      redirect_to admin_purchase_path(@purchase), notice: "Recepción deshecha: stock restado."
    end

    private

    def set_purchase
      @purchase = Purchase.includes(purchase_lines: :product).find(params[:id])
    end

    # Huecos para añadir líneas nuevas en el formulario (sin JavaScript).
    def build_blank_lines
      3.times { @purchase.purchase_lines.build }
    end

    def purchase_params
      params.require(:purchase).permit(:supplier_id, :reference, :ordered_on, :shipping_cost,
                                       :customs_cost, :other_costs, :notes, :invoice,
                                       :currency, :invoice_date, :exchange_rate,
                                       purchase_lines_attributes: [ :id, :product_id, :quantity, :unit_cost, :_destroy ])
    end
  end
end
