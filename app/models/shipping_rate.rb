# Precio base del transporte a cada país de la UE, configurable desde el admin.
# A ese base se suma el coste por unidad de cada producto (shipping_unit_cost).
class ShippingRate < ApplicationRecord
  # Valores por defecto si un país aún no tiene tarifa guardada (los históricos).
  DEFAULT_BASE = BigDecimal("5.95")
  DEFAULT_FOREIGN_SURCHARGE = BigDecimal("8")

  validates :country, presence: true, uniqueness: true, inclusion: { in: Order::EU_COUNTRIES }
  validates :base_cost, numericality: { greater_than_or_equal_to: 0 }

  # Base de envío para un país: su tarifa guardada o el valor por defecto.
  def self.base_for(country)
    find_by(country: country)&.base_cost ||
      (country == "España" ? DEFAULT_BASE : DEFAULT_BASE + DEFAULT_FOREIGN_SURCHARGE)
  end
end
