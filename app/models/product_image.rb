class ProductImage < ApplicationRecord
  belongs_to :product

  validates :url, presence: true

  scope :ordered, -> { order(:position, :id) }
end
