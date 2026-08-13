# Línea de una factura emitida (copia congelada de la línea de origen).
class InvoiceLine < ApplicationRecord
  belongs_to :invoice, inverse_of: :lines

  validates :description, presence: true
  validates :quantity, :unit_price, :total, presence: true
end
