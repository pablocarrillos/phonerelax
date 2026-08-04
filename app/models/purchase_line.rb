# Línea de una compra: unidades de un producto, lo pagado por unidad y los
# costes de transporte, aduanas y otros imputados a esta línea concreta.
class PurchaseLine < ApplicationRecord
  belongs_to :purchase, inverse_of: :purchase_lines
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :shipping_cost, :customs_cost, :other_costs,
            numericality: { greater_than_or_equal_to: 0 }

  # Coste de los productos de la línea, sin extras (en la moneda de la compra).
  def subtotal
    unit_cost * quantity
  end

  # Transporte + aduanas + otros costes imputados a la línea.
  def extra_costs
    shipping_cost + customs_cost + other_costs
  end

  # Total de la línea: productos + extras (en la moneda de la compra).
  def total
    subtotal + extra_costs
  end

  # Coste real por unidad (total de la línea repartido entre sus unidades),
  # en la moneda de la compra.
  def landed_unit_cost
    quantity.to_i.zero? ? total : total / quantity
  end
end
