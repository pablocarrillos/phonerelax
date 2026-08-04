# Mensaje del formulario público de contacto. Ya no se persiste: se valida aquí
# y se reenvía por email (ContactMailer). La tabla conserva los mensajes antiguos.
class ContactMessage < ApplicationRecord
  validates :name, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :phone_looks_valid

  private

  # Si se indica teléfono, debe ser válido (español por defecto o internacional con prefijo).
  def phone_looks_valid
    return if phone.blank? || Phonelib.parse(phone).valid?

    errors.add(:phone, "no parece un número de teléfono válido")
  end
end
