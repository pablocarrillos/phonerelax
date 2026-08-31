# Fichero subido por un administrador para compartir por su URL pública (p. ej.
# incrustado o enlazado en correos): fotos, PDF o cualquier documento. Solo los
# admins pueden subir/gestionar; el fichero es accesible públicamente a través
# de su URL de Active Storage.
class Photo < ApplicationRecord
  has_one_attached :image

  validates :image, presence: true

  def image?
    image.attached? && image.content_type.to_s.start_with?("image/")
  end

  scope :recent_first, -> { order(created_at: :desc) }

  # Busca por comentario o por nombre de archivo.
  scope :search, lambda { |term|
    next if term.blank?

    like = "%#{sanitize_sql_like(term.strip)}%"
    left_joins(image_attachment: :blob)
      .where("photos.comment ILIKE :q OR active_storage_blobs.filename ILIKE :q", q: like)
  }
end
