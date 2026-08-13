# frozen_string_literal: true

require "net/http"
require "json"

module Verifactu
  # Cliente REST de TICKETBAIWS (TicketBAI / VeriFactu), igual que en agua.
  # Auth por cabeceras Token (API) y Nif (emisor). Body JSON.
  # Endpoints: POST /tbai/ (alta), DELETE /tbai/ (anulación).
  class Client
    def initialize(setting = CompanySetting.current)
      @setting = setting
    end

    def submit(payload)
      request(Net::HTTP::Post, "/tbai/", payload)
    end

    def cancel(serie, numero)
      request(Net::HTTP::Delete, "/tbai/", { serie: serie, numero: numero })
    end

    private

    def request(request_class, path, body)
      uri = URI.join(@setting.verifactu_base_url, path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      req = request_class.new(uri)
      req["Accept"] = "application/json"
      req["Content-Type"] = "application/json"
      req["Token"] = @setting.verifactu_token
      req["Nif"] = @setting.tax_id
      req.body = body.to_json

      res = http.request(req)
      interpret(res.code.to_i, res.body)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED,
           Errno::ECONNRESET, Errno::EHOSTUNREACH, SocketError, IOError => e
      raise TemporaryError, e.message
    end

    # Convierte (código HTTP, cuerpo) en un Result. 5xx => error temporal.
    # Público para poder testearlo sin red.
    def interpret(status, raw_body)
      raise TemporaryError, "HTTP #{status}" if status >= 500

      data = parse_json(raw_body)
      ret = data["return"] || {}
      # "PENDING" = ya registrada con huella/QR; la confirmación AEAT es asíncrona.
      if %w[OK PENDING].include?(data["result"])
        Result.new(ok: true, message: data["msg"],
                   huella: ret["huella"] || ret["huella_tbai"],
                   qr: ret["qr"], url: ret["url"])
      else
        Result.new(ok: false, message: data["msg"].presence || "HTTP #{status}")
      end
    end

    def parse_json(raw)
      JSON.parse(raw.to_s)
    rescue JSON::ParserError
      {}
    end
  end
end
