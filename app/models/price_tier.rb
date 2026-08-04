# Escalado de precios de un producto para presupuestos: precio unitario SIN IVA
# a partir de un número mínimo de unidades.
class PriceTier < ApplicationRecord
  belongs_to :product

  validates :min_units, numericality: { only_integer: true, greater_than: 0 },
                        uniqueness: { scope: :product_id }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:min_units) }

  # Precio sin IVA que corresponde a `quantity` unidades del producto: el tramo
  # más alto alcanzado. Sin escalado, cae al PVP de la tienda sin el IVA.
  def self.price_for(product, quantity)
    tier = where(product: product).where(min_units: ..quantity).order(min_units: :desc).first
    tier&.unit_price || (product.price / (1 + (product.vat_percentage.to_d / 100)))
  end
end
