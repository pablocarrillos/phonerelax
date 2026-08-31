module Admin
  # Cupones de descuento de la tienda: se crean y gestionan aquí; el cliente
  # los aplica en el checkout.
  class CouponsController < BaseController
    before_action :set_coupon, only: [ :edit, :update, :destroy ]

    def index
      @coupons = Coupon.recent_first
    end

    def new
      @coupon = Coupon.new(enabled: true)
    end

    def create
      @coupon = Coupon.new(coupon_params)
      if @coupon.save
        redirect_to admin_coupons_path, notice: "Cupón #{@coupon.code} creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @coupon.update(coupon_params)
        redirect_to admin_coupons_path, notice: "Cupón #{@coupon.code} guardado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @coupon.destroy
      redirect_to admin_coupons_path, notice: "Cupón #{@coupon.code} borrado (los pedidos que lo usaron conservan su descuento)."
    end

    private

    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

    def coupon_params
      params.require(:coupon).permit(:code, :enabled, :starts_on, :ends_on, :max_uses,
                                     :discount_percent, :discount_amount, :notify_emails)
    end
  end
end
