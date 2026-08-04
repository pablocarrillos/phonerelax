# Envío de correo por SMTP vía SendGrid cuando hay API key en el entorno.
#
# En desarrollo: define SENDGRID_API_KEY en config/local_env.yml.
# En producción (dokku): dokku config:set SENDGRID_API_KEY=SG.xxxx
# Sin la key, se mantiene el comportamiento por defecto del entorno (no envía).
#
# El remitente (info@phonerelax.com) debe estar verificado en SendGrid: o bien
# autenticando el dominio phonerelax.com (DNS), o como "single sender".
# En test nunca: el entorno usa :test y los asserts cuentan las entregas.
if ENV["SENDGRID_API_KEY"].present? && !Rails.env.test?
  ActionMailer::Base.smtp_settings = {
    address:              "smtp.sendgrid.net",
    port:                 587,
    domain:               ENV["SMTP_DOMAIN"].presence || "phonerelax.com",
    user_name:            "apikey", # literal exigido por SendGrid
    password:             ENV["SENDGRID_API_KEY"],
    authentication:       :plain,
    enable_starttls_auto: true
  }
  ActionMailer::Base.delivery_method       = :smtp
  ActionMailer::Base.perform_deliveries    = true
  ActionMailer::Base.raise_delivery_errors = true
end
