class Product < ApplicationRecord
  has_many :order_lines, dependent: :restrict_with_error
  has_many :product_images, -> { ordered }, dependent: :destroy, inverse_of: :product

  validates :name, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  # Agotado: se sigue mostrando en la tienda pero no se puede comprar.
  def out_of_stock?
    stock <= 0
  end

  # Galería de la ficha: las imágenes gestionadas, o la de portada si no hay ninguna.
  def gallery_urls
    urls = product_images.map(&:url)
    urls.presence || [image_url].compact_blank
  end
end
