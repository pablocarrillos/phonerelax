# Cupón en el checkout: valida el código («Usar») y lo deja en la sesión para
# aplicarlo al crear el pedido; también se puede quitar.
class CouponsController < ApplicationController
  allow_unauthenticated_access

  REJECTIONS = {
    disabled: "Este cupón no está activo.",
    not_started: "Este cupón aún no está en vigor.",
    expired: "Este cupón ha caducado.",
    exhausted: "Este cupón ya ha alcanzado su número máximo de usos."
  }.freeze

  def validate
    coupon = Coupon.lookup(params[:code])
    if coupon.nil?
      session.delete(:coupon_code)
      render json: { valid: false, message: t("checkout.coupon_not_found", default: "Ese cupón no existe.") }
    elsif coupon.redeemable?
      session[:coupon_code] = coupon.code
      render json: { valid: true, code: coupon.code,
                     message: t("checkout.coupon_applied", default: "Cupón %{code} aplicado.") % { code: coupon.code } }
    else
      session.delete(:coupon_code)
      render json: { valid: false, message: REJECTIONS[coupon.rejection_reason] }
    end
  end

  def remove
    session.delete(:coupon_code)
    redirect_back fallback_location: new_order_path
  end
end
