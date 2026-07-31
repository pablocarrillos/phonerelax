# Vista previa de los correos en http://localhost:3002/rails/mailers
class OrderMailerPreview < ActionMailer::Preview
  def paid
    OrderMailer.paid(Order.pago_pagado.last || Order.last)
  end

  def shipped
    OrderMailer.shipped(Order.enviado.last || Order.last)
  end

  def payment_reminder
    OrderMailer.payment_reminder(Order.pago_pendiente.last || Order.last)
  end
end
