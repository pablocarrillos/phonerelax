# Correos de aviso al cliente sobre su pedido.
class OrderMailer < ApplicationMailer
  # Confirmación de pago recibido.
  def paid(order)
    @order = order
    mail(to: @order.email, subject: "PhoneRelax · Pago recibido de tu pedido #{@order.number}")
  end

  # El pedido ha salido hacia su dirección.
  def shipped(order)
    @order = order
    mail(to: @order.email, subject: "PhoneRelax · Tu pedido #{@order.number} está en camino")
  end

  # Recordatorio manual para pedidos que se quedaron sin pagar.
  def payment_reminder(order)
    @order = order
    mail(to: @order.email, subject: "PhoneRelax · Tu pedido #{@order.number} está pendiente de pago")
  end
end
