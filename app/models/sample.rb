# Muestra de producto enviada a un posible cliente (colegio, ayuntamiento…),
# con su fecha de envío y de recogida/devolución.
class Sample < ApplicationRecord
  # Presupuesto al que va asociada la muestra (opcional).
  belongs_to :quote, optional: true
  # Lead desde el que se envió la muestra (opcional): queda en su historial.
  belongs_to :lead, optional: true
  has_many :sample_lines, dependent: :destroy, inverse_of: :sample

  accepts_nested_attributes_for :sample_lines, allow_destroy: true,
                                               reject_if: ->(attrs) { attrs["product_id"].blank? }

  validates :organization, presence: true

  scope :recent_first, -> { order(sent_on: :desc, id: :desc) }
  scope :pending, -> { where(returned_on: nil) }
  scope :returned, -> { where.not(returned_on: nil) }
  scope :sold, -> { where(sold: true) }

  def returned?
    returned_on.present?
  end

  # Coste unitario de un producto para valorar muestras: su coste real medio de
  # las compras recibidas o, si no hay compras, su PVP sin IVA.
  def self.unit_cost_for(product, landed_costs = {})
    landed_costs.dig(product, :avg_cost) || (product.price / (1 + (product.vat_percentage.to_d / 100)))
  end

  # Coste de esta muestra según sus líneas.
  def cost(landed_costs = {})
    sample_lines.sum { |line| self.class.unit_cost_for(line.product, landed_costs) * line.quantity }
  end
end
