# Histórico de un presupuesto: creado, cambios de estado, de pago, albarán…
class QuoteEvent < ApplicationRecord
  belongs_to :quote

  validates :event, presence: true

  scope :chronological, -> { order(:created_at, :id) }
end
