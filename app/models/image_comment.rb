# Comentario asociado a una imagen estática del proyecto (public/images), para
# poder buscarla desde la herramienta de Fotos del admin. La clave es la ruta
# pública de la imagen (/images/…).
class ImageComment < ApplicationRecord
  validates :path, presence: true, uniqueness: true
end
