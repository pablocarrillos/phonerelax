class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("EMAIL_FROM", "PhoneRelax <info@phonerelax.com>")
  layout "mailer"

  # Añade el prefijo de idioma a las URLs de los correos según el idioma activo
  # (el español, idioma por defecto, va sin prefijo). Conserva el host de la config.
  def default_url_options
    base = self.class.default_url_options || {}
    I18n.locale == I18n.default_locale ? base : base.merge(locale: I18n.locale.to_s)
  end
end
