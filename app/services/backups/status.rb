# frozen_string_literal: true

module Backups
  # Estado de las copias, para `backups:check` y el aviso por correo.
  class Status
    DB_PREFIX = "phonerelax/db/"
    FILES_PREFIX = "phonerelax/files/"
    # margen antes de dar la voz de alarma: las copias son diarias, así que
    # más de 36 horas significa que ayer falló.
    STALE_AFTER = 36.hours

    Part = Struct.new(:name, :at, :size, :key, :error, keyword_init: true) do
      def missing? = at.nil?
      def stale?(now = Time.current) = at.present? && at < now - STALE_AFTER
      def ok?(now = Time.current) = error.nil? && !missing? && !stale?(now)
    end

    # El almacén se puede pasar hecho (tests); si no, se monta con las
    # credenciales del entorno, y si no las hay queda sin configurar.
    def initialize(store: nil)
      @store = store || (Store.new if Store.configured?)
    end

    def parts
      @parts ||= [ part("base de datos", DB_PREFIX), part("archivos subidos", FILES_PREFIX) ]
    end

    def ok? = parts.all?(&:ok?)
    def configured? = @store.present?

    # Qué contar en el aviso, en cristiano.
    def problems
      parts.reject(&:ok?).map do |part|
        next "#{part.name}: #{part.error}" if part.error
        next "#{part.name}: no hay ninguna copia en el bucket" if part.missing?

        "#{part.name}: la última es del #{I18n.l(part.at.in_time_zone, format: '%d-%m-%Y a las %H:%M')}"
      end
    end

    private

    def part(name, prefix)
      return Part.new(name: name, error: "no hay credenciales configuradas (BACKUP_S3_*)") unless configured?

      latest = @store.latest(prefix)
      Part.new(name: name, at: latest&.dig(:at), size: latest&.dig(:size), key: latest&.dig(:key))
    rescue StandardError => e
      Part.new(name: name, error: "no se ha podido consultar el bucket (#{e.class}: #{e.message})")
    end
  end
end
