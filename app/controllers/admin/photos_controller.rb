module Admin
  # Herramienta de fotos: subir imágenes (solo admins) y compartirlas por su
  # URL pública, con comentario y buscador.
  class PhotosController < BaseController
    def index
      @query = params[:q].to_s.strip
      @photos = Photo.recent_first.with_attached_image.search(@query) || Photo.recent_first.with_attached_image
    end

    # Admite varias imágenes a la vez; todas comparten el comentario indicado.
    def create
      files = Array(params[:images]).reject(&:blank?)
      return redirect_to admin_photos_path, alert: "Selecciona al menos una imagen." if files.empty?

      files.each { |file| Photo.create!(image: file, comment: params[:comment].to_s.strip) }
      redirect_to admin_photos_path, notice: "#{files.size == 1 ? 'Foto subida' : "#{files.size} fotos subidas"}."
    end

    def update
      photo = Photo.find(params[:id])
      photo.update!(comment: params[:photo][:comment].to_s.strip)
      redirect_to admin_photos_path(q: params[:q].presence), notice: "Comentario actualizado."
    end

    def destroy
      Photo.find(params[:id]).destroy!
      redirect_to admin_photos_path, notice: "Foto borrada."
    end
  end
end
