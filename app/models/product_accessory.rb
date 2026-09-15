class ProductAccessory < ApplicationRecord
  belongs_to :product
  belongs_to :accessory, class_name: "Product"

  scope :ordered, -> { order(:position, :id) }

  validates :accessory_id, uniqueness: { scope: :product_id }
  validate :not_itself

  private

  def not_itself
    errors.add(:accessory_id, "no puede ser el propio producto") if accessory_id == product_id
  end
end
