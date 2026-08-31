module Admin
  # Herramienta de fotos: subir imágenes (solo admins) y compartirlas por su
  # URL pública, con comentario y buscador. Además de las subidas, lista las
  # imágenes estáticas del propio proyecto (public/images) para poder copiar
  # también sus URLs.
  class PhotosController < BaseController
    IMAGE_EXTENSIONS = %w[jpg jpeg png webp gif svg].freeze

    def index
      @query = params[:q].to_s.strip
      @photos = Photo.recent_first.with_attached_image.search(@query) || Photo.recent_first.with_attached_image
      @image_comments = ImageComment.all.index_by(&:path)
      @project_images = project_images
    end

    # Guarda (o crea) el comentario de una imagen estática del proyecto.
    def project_comment
      path = params[:path].to_s
      return redirect_to admin_photos_path, alert: "Imagen no válida." unless valid_project_image?(path)

      ImageComment.find_or_initialize_by(path: path).update!(comment: params[:comment].to_s.strip)
      redirect_to admin_photos_path(q: params[:q].presence), notice: "Comentario guardado."
    end

    # Admite varios ficheros a la vez (fotos, PDF, lo que sea); todos comparten el comentario indicado.
    def create
      files = Array(params[:images]).reject(&:blank?)
      return redirect_to admin_photos_path, alert: "Selecciona al menos un fichero." if files.empty?

      files.each { |file| Photo.create!(image: file, comment: params[:comment].to_s.strip) }
      redirect_to admin_photos_path, notice: "#{files.size == 1 ? 'Fichero subido' : "#{files.size} ficheros subidos"}."
    end

    def update
      photo = Photo.find(params[:id])
      photo.update!(comment: params[:photo][:comment].to_s.strip)
      redirect_to admin_photos_path(q: params[:q].presence), notice: "Comentario actualizado."
    end

    def destroy
      Photo.find(params[:id]).destroy!
      redirect_to admin_photos_path, notice: "Fichero borrado."
    end

    private

    # Imágenes estáticas del proyecto como { path:, dims:, bytes: }, filtradas
    # por el término de búsqueda (ruta o comentario) si lo hay.
    def project_images
      root = Rails.public_path.join("images")
      paths = Dir.glob(root.join("**", "*.{#{IMAGE_EXTENSIONS.join(',')}}"))
                 .map { |f| "/images/#{Pathname(f).relative_path_from(root)}" }
                 .sort
      unless @query.blank?
        q = @query.downcase
        paths = paths.select do |p|
          p.downcase.include?(q) || @image_comments[p]&.comment.to_s.downcase.include?(q)
        end
      end
      paths.map do |path|
        file = Rails.public_path.join(path.delete_prefix("/"))
        { path: path, dims: FastImage.size(file.to_s), bytes: file.size? }
      end
    end

    # Solo se admiten rutas reales dentro de public/images (sin traversal).
    def valid_project_image?(path)
      return false unless path.start_with?("/images/") && !path.include?("..")

      Rails.public_path.join(path.delete_prefix("/")).file?
    end
  end
end
