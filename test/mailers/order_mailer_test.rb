require 'test_helper'

class OrderMailerTest < ActionMailer::TestCase
  setup { ActionMailer::Base.default_url_options = { host: 'phonerelax.com' } }

  test 'paid: pedido en español -> correo en español y enlace sin prefijo' do
    order = orders(:uno)
    order.update!(locale: 'es')
    mail = OrderMailer.paid(order)

    assert_match 'Pago recibido', mail.subject
    body = mail.body.decoded
    assert_match 'Gracias por tu compra', body
    assert_match 'http://phonerelax.com/pedido/', body
    assert_no_match %r{/pt/pedido/}, body
  end

  test 'paid: pedido en portugués -> correo en portugués y enlace con /pt' do
    order = orders(:uno)
    order.update!(locale: 'pt')
    mail = OrderMailer.paid(order)

    assert_match 'Pagamento recebido', mail.subject
    body = mail.body.decoded
    assert_match 'Obrigado pela sua compra', body
    assert_match 'http://phonerelax.com/pt/pedido/', body
  end

  test 'el idioma del correo no depende del idioma activo del que lo dispara' do
    order = orders(:uno)
    order.update!(locale: 'pt')
    # Aunque se dispare con la app en español, el correo sale en el idioma del pedido.
    mail = I18n.with_locale(:es) { OrderMailer.paid(order) }
    assert_match 'Pagamento recebido', mail.subject
  end
end
