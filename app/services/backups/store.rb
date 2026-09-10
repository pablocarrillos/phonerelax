# frozen_string_literal: true

module Backups
  # Acceso al bucket de copias (DigitalOcean Spaces, compatible con S3). Es el
  # mismo bucket que usan agua, avisos, gestion y delivery_note_app, cada uno
  # bajo su propia carpeta.
  #
  # Sin credenciales configuradas el servicio queda "sin configurar" en vez de
  # reventar: así `backups:check` lo dice claramente y no se rompe nada.
  class Store
    class NotConfigured < StandardError; end

    def self.configured?
      ENV["BACKUP_S3_BUCKET"].present? && ENV["BACKUP_S3_ACCESS_KEY_ID"].present?
    end

    def initialize
      raise NotConfigured, "faltan las variables BACKUP_S3_*" unless self.class.configured?

      @bucket = ENV.fetch("BACKUP_S3_BUCKET")
    end

    attr_reader :bucket

    def client
      @client ||= begin
        require "aws-sdk-s3"
        options = { region: ENV.fetch("BACKUP_S3_REGION", "fra1"),
                    access_key_id: ENV.fetch("BACKUP_S3_ACCESS_KEY_ID"),
                    secret_access_key: ENV.fetch("BACKUP_S3_SECRET_ACCESS_KEY") }
        endpoint = ENV["BACKUP_S3_ENDPOINT"].presence
        options[:endpoint] = endpoint if endpoint
        Aws::S3::Client.new(**options)
      end
    end

    # Sube el fichero por partes: el archivo de ficheros pasa de 300 MB y una
    # subida en un solo trozo desde este droplet es frágil.
    def upload(key, path)
      File.open(path, "rb") do |file|
        Aws::S3::Object.new(bucket_name: bucket, key: key, client: client)
                       .upload_stream(part_size: 16 * 1024 * 1024) { |write| IO.copy_stream(file, write) }
      end
      key
    end

    # La copia más reciente bajo un prefijo, o nil si no hay ninguna.
    def latest(prefix)
      newest = nil
      client.list_objects_v2(bucket: bucket, prefix: prefix).each do |page|
        page.contents.each do |object|
          newest = object if newest.nil? || object.last_modified > newest.last_modified
        end
      end
      return nil unless newest

      { key: newest.key, at: newest.last_modified, size: newest.size }
    end

    # Se queda con las N copias más recientes de un prefijo y borra el resto,
    # para que el bucket no crezca sin fin.
    def prune(prefix, keep:)
      objects = []
      client.list_objects_v2(bucket: bucket, prefix: prefix).each { |page| objects.concat(page.contents) }
      extra = objects.sort_by(&:last_modified).reverse.drop(keep)
      extra.each { |object| client.delete_object(bucket: bucket, key: object.key) }
      extra.size
    end
  end
end
