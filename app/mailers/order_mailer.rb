# Correos de aviso al cliente sobre su pedido. Se envían en el idioma en que el
# cliente completó la compra (order.locale), no en el idioma del que los dispara.
class OrderMailer < ApplicationMailer
  # Avisos internos: admite varias cuentas separadas por comas en CONTACT_EMAIL.
  SHOP_RECIPIENTS = ENV.fetch("CONTACT_EMAIL", "info@phonerelax.com,phonerelaxstore@gmail.com")
                       .split(",").map(&:strip)

  # Aviso interno a la tienda (en español): pedido creado con los datos de
  # contacto del cliente, todavía pendiente de pago.
  def new_order(order)
    @order = order
    mail(to: SHOP_RECIPIENTS, reply_to: @order.email,
         subject: "🛒 Pedido creado (sin pagar): #{@order.number} · #{format('%.2f', @order.amount_paid)} €")
  end

  # Aviso interno a la tienda (en español): pedido cobrado, con los artículos
  # y los datos de envío del cliente.
  def new_sale(order)
    @order = order
    mail(to: SHOP_RECIPIENTS, reply_to: @order.email,
         subject: "💰 Pedido pagado: #{@order.number} · #{format('%.2f', @order.amount_paid)} €")
  end

  # Confirmación de pago recibido.
  def paid(order)
    @order = order
    with_order_locale do
      mail(to: @order.email, subject: t("order_mailer.paid.subject", number: @order.number))
    end
  end

  # El pedido ha salido hacia su dirección.
  def shipped(order)
    @order = order
    with_order_locale do
      mail(to: @order.email, subject: t("order_mailer.shipped.subject", number: @order.number))
    end
  end

  # Aviso al cliente de un reembolso (total o parcial) sobre su pedido.
  def refunded(order, amount)
    @order = order
    @amount = amount
    with_order_locale do
      mail(to: @order.email, subject: t("order_mailer.refunded.subject", number: @order.number))
    end
  end

  # Recordatorio manual para pedidos que se quedaron sin pagar.
  def payment_reminder(order)
    @order = order
    with_order_locale do
      mail(to: @order.email, subject: t("order_mailer.payment_reminder.subject", number: @order.number))
    end
  end

  private

  def with_order_locale(&block)
    I18n.with_locale(@order.locale.presence || I18n.default_locale, &block)
  end
end
