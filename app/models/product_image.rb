class ProductImage < ApplicationRecord
  belongs_to :product
  has_one_attached :file

  # Las imágenes nuevas se suben como fichero; `url` queda para las antiguas.
  validates :url, presence: true, unless: -> { file.attached? }

  scope :ordered, -> { order(:position, :id) }

  # Ruta de la imagen: el fichero subido o, para las históricas, su URL.
  def src
    if file.attached?
      Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
    else
      url
    end
  end
end
