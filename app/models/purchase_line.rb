# Línea de una compra: unidades de un producto de la tienda O un concepto
# libre (maquinaria, cajas…), lo pagado por unidad y los costes de transporte,
# aduanas y otros imputados a esta línea concreta. Las líneas de concepto libre
# no suman stock ni entran en el coste real por producto.
class PurchaseLine < ApplicationRecord
  belongs_to :purchase, inverse_of: :purchase_lines
  belongs_to :product, optional: true
  # presupuesto de cliente al que se imputa el coste de esta línea (opcional:
  # en blanco es compra para stock general)
  belongs_to :quote, optional: true

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :shipping_cost, :customs_cost, :other_costs,
            numericality: { greater_than_or_equal_to: 0 }
  validates :vat_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validate :product_or_description

  # Un coste extra dejado en blanco en el formulario significa 0, no un error.
  before_validation -> { self.shipping_cost ||= 0; self.customs_cost ||= 0; self.other_costs ||= 0; self.vat_rate ||= 0 }

  # Qué se compró: el producto de la tienda o el concepto libre.
  def display_name
    product&.name || description
  end

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

  # Total de la línea en euros (aplica el tipo de cambio de la compra si es USD).
  def total_eur
    total * purchase.eur_rate
  end

  # IVA soportado de la línea (sobre productos + extras). No entra en el coste
  # real: es deducible.
  def vat_amount
    total * vat_rate / 100
  end

  # Lo que se paga por la línea: base + IVA (en la moneda de la compra).
  def total_with_vat
    total + vat_amount
  end

  private

  def product_or_description
    return if product.present? || description.present?

    errors.add(:base, "Cada línea necesita un producto de la tienda o un concepto libre")
  end
end
