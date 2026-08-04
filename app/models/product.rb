class Product < ApplicationRecord
  include Translatable
  translates :name, :description

  has_many :order_lines, dependent: :restrict_with_error
  has_many :product_images, -> { ordered }, dependent: :destroy, inverse_of: :product
  has_one_attached :cover_image

  validates :name, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  # URL amigable: usa el handle de Shopify como slug (/producto/funda-...);
  # si faltara, cae al id para no romper enlaces.
  def to_param
    shopify_handle.presence || id.to_s
  end

  # Resuelve el parámetro de la URL: slug (handle) o, para enlaces antiguos, id numérico.
  def self.find_by_param(param)
    find_by(shopify_handle: param) || (find_by(id: param) if param.to_s.match?(/\A\d+\z/))
  end

  def self.find_by_param!(param)
    find_by_param(param) || raise(ActiveRecord::RecordNotFound, "Couldn't find Product with param #{param.inspect}")
  end

  # Agotado: se sigue mostrando en la tienda pero no se puede comprar.
  def out_of_stock?
    stock <= 0
  end

  # Portada: la imagen subida desde el admin o, para productos antiguos que aún
  # no la tienen, la ruta estática guardada en image_url.
  def cover_url
    if cover_image.attached?
      Rails.application.routes.url_helpers.rails_blob_path(cover_image, only_path: true)
    else
      image_url
    end
  end

  # Galería de la ficha: las imágenes gestionadas, o la de portada si no hay ninguna.
  def gallery_urls
    urls = product_images.map(&:url)
    urls.presence || [ cover_url ].compact_blank
  end
end
