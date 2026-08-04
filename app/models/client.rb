# Cliente de presupuestos (colegios, ayuntamientos, empresas) con sus datos
# fiscales tal y como deben aparecer en el PDF.
class Client < ApplicationRecord
  has_many :quotes, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :ordered, -> { order(:name) }
end
