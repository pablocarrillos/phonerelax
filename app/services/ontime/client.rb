require "net/http"
require "json"

module Ontime
  # Cliente mínimo de la API REST de Ontime (Oracle ORDS). Autenticación: HTTP
  # Basic (ONTIME_API_USER:ONTIME_API_PASSWORD) + cabecera X-Api-Key
  # (ONTIME_API_TOKEN). Entorno por ONTIME_BASE_URL (por defecto el sandbox PRE,
  # para no llamar a producción sin querer). Credenciales en config/local_env.yml.
  class Client
    class Error < StandardError; end

    DEFAULT_BASE_URL = "https://clientespre.ontime.es/ords/core".freeze

    # ZPL de la etiqueta de un envío. Requiere el nº de seguimiento y el código
    # postal de destino (la API los exige a ambos en la ruta).
    def label_zpl(tracking:, postal_code:)
      body = get("/v1/shipments/#{tracking}/#{postal_code}/label")
      raise Error, error_message(body) unless body["success"]

      body.dig("label", "content").to_s
    end

    private

    def get(path)
      require_credentials!
      uri = URI.parse("#{base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Get.new(uri)
      request.basic_auth(api_user, api_password)
      request["X-Api-Key"] = api_token
      request["Accept"] = "application/json"

      response = http.request(request)
      code = response.code.to_i
      raise Error, "Ontime rechazó las credenciales (HTTP #{code})" if [ 401, 403 ].include?(code)

      # Ontime usa 404 con un sobre {success:false, errorCode, message} para
      # «envío no encontrado»; se parsea igual y lo interpreta quien llama.
      parse_body(response.body, code)
    rescue SocketError, Net::OpenTimeout, Net::ReadTimeout, IOError => e
      raise Error, "no se pudo conectar con Ontime: #{e.message}"
    end

    def parse_body(raw, code)
      JSON.parse(raw)
    rescue JSON::ParserError
      raise Error, "Ontime respondió HTTP #{code}"
    end

    # Mensaje claro para el usuario a partir del sobre de error de Ontime.
    def error_message(body)
      return "No existe ningún envío con ese nº de seguimiento y código postal." if body["errorCode"] == "SHIPMENT_NOT_FOUND"

      body["message"].presence || "Ontime no devolvió la etiqueta"
    end

    def require_credentials!
      return if api_user.present? && api_password.present? && api_token.present?

      raise Error, "faltan credenciales de Ontime (ONTIME_API_USER/PASSWORD/TOKEN en config/local_env.yml)"
    end

    def base_url = ENV.fetch("ONTIME_BASE_URL", DEFAULT_BASE_URL)
    def api_user = ENV["ONTIME_API_USER"]
    def api_password = ENV["ONTIME_API_PASSWORD"]
    def api_token = ENV["ONTIME_API_TOKEN"]
  end
end
