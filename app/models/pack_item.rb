# Componente de un pack: N unidades de un producto dentro de un producto-pack.
class PackItem < ApplicationRecord
  belongs_to :pack, class_name: "Product", inverse_of: :pack_items
  belongs_to :component, class_name: "Product"

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validate :component_is_not_a_pack

  scope :ordered, -> { order(:position, :id) }

  private

  # Un pack no puede contener otro pack (evita anidamientos y bucles de precio).
  def component_is_not_a_pack
    errors.add(:component, "no puede ser otro pack") if component&.pack?
  end
end
