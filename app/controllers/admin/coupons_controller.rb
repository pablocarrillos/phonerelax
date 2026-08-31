module Admin
  # Cupones de descuento de la tienda: se crean y gestionan aquí; el cliente
  # los aplica en el checkout.
  class CouponsController < BaseController
    before_action :set_coupon, only: [ :edit, :update, :destroy ]

    def index
      @coupons = Coupon.recent_first
      load_uses
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

    # Uso de los cupones: pedidos cobrados (o luego reembolsados) con cupón,
    # filtrables por cupón concreto y por rango de fecha/hora del pedido.
    def load_uses
      @uses_coupon = Coupon.find_by(id: params[:coupon_id])
      @uses_from = parse_time(params[:from])
      @uses_to = parse_time(params[:to])

      uses = Order.where.not(coupon_id: nil).where.not(payment_status: :pendiente)
                  .includes(:coupon).order(created_at: :desc)
      uses = uses.where(coupon_id: @uses_coupon.id) if @uses_coupon
      uses = uses.where(created_at: @uses_from..) if @uses_from
      uses = uses.where(created_at: ..@uses_to) if @uses_to
      @uses = uses.to_a

      @uses_total_gross = @uses.sum { |order| order.total.to_d }
      @uses_total_net = @uses.sum { |order| order.total.to_d - order.vat_breakdown[:vat] }
      @uses_total_discount = @uses.sum { |order| order.coupon_discount.to_d }
    end

    def parse_time(value)
      Time.zone.parse(value.to_s.strip.presence || "")
    rescue ArgumentError
      nil
    end

    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

    def coupon_params
      params.require(:coupon).permit(:code, :enabled, :starts_on, :ends_on, :max_uses,
                                     :discount_percent, :discount_amount, :notify_emails)
    end
  end
end
