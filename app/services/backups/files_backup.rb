# frozen_string_literal: true

require "tmpdir"

module Backups
  # Copia de todo lo subido a la aplicación: fotos de producto, imágenes de
  # entradas, adjuntos de presupuestos (logo, DTF, muestra aprobada, firmado) y
  # las COPIAS EN PDF DE LAS FACTURAS EMITIDAS. Todo vive en el disco local, en
  # app/storage, así que se empaqueta y se sube al mismo bucket que el volcado.
  class FilesBackup
    KEEP = 14 # copias que se conservan en el bucket

    def initialize(store: Store.new, root: Rails.root.join("storage"))
      @store = store
      @root = Pathname.new(root)
    end

    def run(now: Time.current)
      raise "no existe el directorio de archivos (#{@root})" unless @root.directory?

      key = "#{Status::FILES_PREFIX}phonerelax-files-#{now.strftime('%Y%m%d-%H%M')}.tar.gz"
      Dir.mktmpdir do |dir|
        path = File.join(dir, File.basename(key))
        pack(path)
        size = File.size(path)
        raise "el archivo de copia ha salido vacío" if size.zero?

        @store.upload(key, path)
        @store.prune(Status::FILES_PREFIX, keep: KEEP)
        { key: key, size: size, files: count_files }
      end
    end

    private

    # -C para guardar rutas relativas: así se restaura en cualquier sitio.
    # Casi todo son imágenes ya comprimidas, así que se comprime al mínimo:
    # en esta máquina (2 GB de RAM, compartida con los vhosts de PHP) importa
    # más no comerse la CPU que arañar unos megas.
    def pack(path)
      ok = system("nice", "-n", "19", "tar", "-I", "gzip -1", "-cf", path,
                  "-C", @root.parent.to_s, @root.basename.to_s)
      raise "no se ha podido empaquetar #{@root}" unless ok
    end

    def count_files
      Dir.glob(@root.join("**", "*")).count { |entry| File.file?(entry) }
    end
  end
end
