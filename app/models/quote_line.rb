# Línea de un presupuesto: descripción, unidades y precio unitario SIN IVA.
# Puede venir de un producto del catálogo (activo o no) o escribirse libre.
class QuoteLine < ApplicationRecord
  belongs_to :quote, inverse_of: :quote_lines
  belongs_to :product, optional: true

  validates :description, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :vat_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  def discounted?
    discount_percent.to_d.positive?
  end

  # Total de la línea con su descuento aplicado.
  def total
    ((unit_price * quantity) * (1 - (discount_percent.to_d / 100))).round(2)
  end
end
