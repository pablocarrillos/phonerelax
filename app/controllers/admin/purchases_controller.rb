module Admin
  class PurchasesController < BaseController
    before_action :set_purchase, only: [ :show, :edit, :update, :destroy, :receive, :unreceive ]

    def index
      @purchases = Purchase.includes(:supplier, purchase_lines: :product).recent_first
      @landed_costs = Purchase.average_landed_costs
    end

    def show; end

    def new
      # supplier_id: el botón «Nuevo pedido» de la lista de proveedores llega
      # con el proveedor ya elegido
      @purchase = Purchase.new(ordered_on: Date.current, supplier_id: params[:supplier_id].presence)
      build_blank_lines
      load_quotes_for_imputation
    end

    def create
      @purchase = Purchase.new(purchase_params)
      if @purchase.save
        redirect_to admin_purchase_path(@purchase), notice: "Compra registrada."
      else
        build_blank_lines
        load_quotes_for_imputation
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      build_blank_lines
      load_quotes_for_imputation
    end

    def update
      if @purchase.update(purchase_params)
        redirect_to admin_purchase_path(@purchase), notice: "Compra actualizada."
      else
        build_blank_lines
        load_quotes_for_imputation
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
      params.require(:purchase).permit(:supplier_id, :reference, :ordered_on, :expected_on, :notes, :invoice,
                                       :currency, :invoice_date, :exchange_rate,
                                       purchase_lines_attributes: [ :id, :product_id, :description, :quantity, :unit_cost,
                                                                    :shipping_cost, :customs_cost, :other_costs,
                                                                    :vat_rate, :quote_id, :_destroy ])
    end

    # Presupuestos elegibles para imputar líneas: los más recientes primero,
    # incluyendo los ya imputados en esta compra aunque sean antiguos.
    def load_quotes_for_imputation
      @quotes_for_imputation = Quote.includes(:client).order(created_at: :desc).limit(100).to_a
      missing = @purchase.purchase_lines.filter_map(&:quote_id) - @quotes_for_imputation.map(&:id)
      @quotes_for_imputation |= Quote.includes(:client).where(id: missing).to_a if missing.any?
    end
  end
end
