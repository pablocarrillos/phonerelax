# Cliente de presupuestos (colegios, ayuntamientos, empresas) con sus datos
# fiscales tal y como deben aparecer en el PDF.
class Client < ApplicationRecord
  has_many :quotes, dependent: :restrict_with_error
  # leads que dieron lugar a este cliente (al añadir sus datos fiscales)
  has_many :leads, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :ordered, -> { order(:name) }
  # Búsqueda por nombre para el autocompletado del formulario de presupuestos.
  scope :name_like, ->(term) { where("name ILIKE ?", "%#{sanitize_sql_like(term.to_s.strip)}%") }
end
