# Foto subida por un administrador para compartir por su URL pública (p. ej.
# incrustada o enlazada en correos). Solo los admins pueden subir/gestionar;
# la imagen es accesible públicamente a través de su URL de Active Storage.
class Photo < ApplicationRecord
  has_one_attached :image

  validates :image, presence: true

  scope :recent_first, -> { order(created_at: :desc) }

  # Busca por comentario o por nombre de archivo.
  scope :search, lambda { |term|
    next if term.blank?

    like = "%#{sanitize_sql_like(term.strip)}%"
    left_joins(image_attachment: :blob)
      .where("photos.comment ILIKE :q OR active_storage_blobs.filename ILIKE :q", q: like)
  }
end
