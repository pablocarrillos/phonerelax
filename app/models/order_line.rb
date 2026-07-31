class OrderLine < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, presence: true

  def subtotal
    unit_price * quantity
  end
end
