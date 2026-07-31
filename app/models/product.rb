class Product < ApplicationRecord
  has_many :order_lines, dependent: :restrict_with_error

  validates :name, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
