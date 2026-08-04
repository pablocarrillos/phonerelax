# Solicitud de presupuesto para pedidos grandes (colegios, empresas, eventos).
class QuoteRequest < ApplicationRecord
  SECTORS = %w[colegio empresa evento academia otro].freeze

  validates :name, :organization, :email, :message, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :units, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :phone_looks_valid

  scope :recent_first, -> { order(created_at: :desc) }

  private

  def phone_looks_valid
    return if phone.blank? || Phonelib.parse(phone).valid?

    errors.add(:phone, "no parece un número de teléfono válido")
  end
end
