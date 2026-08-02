class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('EMAIL_FROM', 'PhoneRelax <info@phonerelax.com>')
  layout "mailer"

  # Añade el prefijo de idioma a las URLs de los correos según el idioma activo
  # (el español, idioma por defecto, va sin prefijo). Conserva el host de la config.
  def default_url_options
    loc = I18n.locale == I18n.default_locale ? nil : I18n.locale
    (self.class.default_url_options || {}).merge(locale: loc)
  end
end
