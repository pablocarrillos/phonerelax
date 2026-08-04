# Línea de una compra: unidades de un producto y lo pagado por unidad.
class PurchaseLine < ApplicationRecord
  belongs_to :purchase, inverse_of: :purchase_lines
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }

  def subtotal
    unit_cost * quantity
  end
end
