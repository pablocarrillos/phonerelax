# frozen_string_literal: true

require "tmpdir"
require "shellwords"

module Backups
  # Volcado completo de PostgreSQL, comprimido y subido al bucket. Aquí no hay
  # plugin de dokku que lo haga (la base de datos vive en la propia máquina),
  # así que lo hace la aplicación con pg_dump.
  class DatabaseBackup
    KEEP = 30 # el volcado ocupa muy poco: se guarda un mes largo

    def initialize(store: Store.new)
      @store = store
    end

    # Devuelve los datos de la copia subida. Cualquier fallo sube como
    # excepción: quien la lanza decide a quién avisar.
    def run(now: Time.current)
      key = "#{Status::DB_PREFIX}phonerelax-db-#{now.strftime('%Y%m%d-%H%M')}.sql.gz"
      Dir.mktmpdir do |dir|
        path = File.join(dir, File.basename(key))
        dump(path)
        size = File.size(path)
        raise "el volcado ha salido vacío" if size.zero?

        @store.upload(key, path)
        @store.prune(Status::DB_PREFIX, keep: KEEP)
        { key: key, size: size }
      end
    end

    private

    # pg_dump con las credenciales que ya usa la aplicación. En producción la
    # conexión es por socket con autenticación peer, así que basta el nombre.
    def dump(path)
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      command = [ "pg_dump", "--no-owner", "--no-acl" ]
      command += [ "--host", config[:host].to_s ] if config[:host].present?
      command += [ "--port", config[:port].to_s ] if config[:port].present?
      command += [ "--username", config[:username].to_s ] if config[:username].present?
      command << config.fetch(:database)

      env = {}
      env["PGPASSWORD"] = config[:password].to_s if config[:password].present?
      ok = system(env, "#{command.shelljoin} | gzip -6 > #{Shellwords.escape(path)}")
      raise "pg_dump ha fallado" unless ok
    end
  end
end
