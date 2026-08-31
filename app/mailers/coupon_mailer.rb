# Aviso al promotor de un cupón: alguien lo ha usado y este es el pedido.
class CouponMailer < ApplicationMailer
  def redeemed(coupon, order, email)
    @coupon = coupon
    @order = order
    mail(to: email, subject: "Cupón #{coupon.code} usado · pedido #{order.number} (#{ActiveSupport::NumberHelper.number_to_rounded(order.total, precision: 2, separator: ',')} €)")
  end
end
