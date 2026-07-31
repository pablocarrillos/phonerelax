class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('EMAIL_FROM', 'PhoneRelax <info@phonerelax.com>')
  layout "mailer"
end
