# Histórico de un pedido: creado, pagado, enviado, entregado.
class OrderEvent < ApplicationRecord
  belongs_to :order

  validates :event, presence: true

  scope :chronological, -> { order(:created_at, :id) }
end
