# Gestión de un lead: cada contacto o hito queda apuntado con su canal, fecha
# y estado resultante; la última gestión fija el estado (y el presupuesto) del
# lead. Las gestiones «Muestra» y «Presupuesto» se crean solas al vincular.
class LeadManagement < ApplicationRecord
  CHANNELS = [ "Llamada", "Correo", "Whatsapp", "Reunión", "Muestra", "Presupuesto" ].freeze
  BUDGET_STATUSES = [ "Presupuestado sucio", "Presupuestado formal" ].freeze

  belongs_to :lead

  validates :status, presence: true, inclusion: { in: Lead::STATUSES }
  validates :channel, presence: true, inclusion: { in: CHANNELS }
  validates :happened_at, :action, presence: true
  validates :budget_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: :budget_status?

  def budget_status?
    BUDGET_STATUSES.include?(status)
  end
end
