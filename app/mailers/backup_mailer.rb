# frozen_string_literal: true

# Aviso cuando una copia de seguridad falla o se queda atrasada. Sin esto, que
# las copias dejen de hacerse no se nota hasta que hacen falta.
class BackupMailer < ApplicationMailer
  RECIPIENTS = ENV.fetch("BACKUP_ALERT_EMAIL", ENV.fetch("CONTACT_EMAIL", "info@phonerelax.com"))

  def failed(problems, context: "La comprobación diaria de las copias ha encontrado problemas.")
    @problems = Array(problems)
    @context = context
    mail(to: RECIPIENTS, subject: "⚠ Copias de seguridad de phonerelax: revisar")
  end
end
