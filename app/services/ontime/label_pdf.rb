require "net/http"

module Ontime
  # PDF de la etiqueta de un envío de Ontime. La API de Ontime solo entrega la
  # etiqueta en ZPL (impresoras térmicas), así que se convierte a PDF con
  # Labelary. El endpoint de Labelary y la rotación son configurables por ENV
  # (LABELARY_URL, ONTIME_LABEL_ROTATION) para poder usar una instancia propia
  # de Labelary o ajustar la orientación.
  class LabelPdf
    class Error < StandardError; end

    # 8dpmm (203 ppp) y etiqueta 4x6", el formato estándar de Ontime.
    DEFAULT_LABELARY_URL = "https://api.labelary.com/v1/printers/8dpmm/labels/4x6/".freeze
    # El ZPL de Ontime va rotado para térmica; 270º lo deja en vertical y legible para A4.
    DEFAULT_ROTATION = "270".freeze

    def self.render(tracking:, postal_code:, client: Ontime::Client.new)
      new(client).render(tracking: tracking, postal_code: postal_code)
    end

    def initialize(client)
      @client = client
    end

    def render(tracking:, postal_code:)
      zpl = @client.label_zpl(tracking: tracking, postal_code: postal_code)
      raise Error, "el envío no tiene etiqueta disponible" if zpl.blank?

      zpl_to_pdf(zpl)
    end

    private

    def zpl_to_pdf(zpl)
      uri = URI.parse(ENV.fetch("LABELARY_URL", DEFAULT_LABELARY_URL))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["Accept"] = "application/pdf"
      request["X-Rotation"] = ENV.fetch("ONTIME_LABEL_ROTATION", DEFAULT_ROTATION)
      request.body = zpl

      response = http.request(request)
      raise Error, "Labelary respondió HTTP #{response.code}" unless response.code.to_i == 200

      response.body
    rescue SocketError, Net::OpenTimeout, Net::ReadTimeout, IOError => e
      raise Error, "no se pudo convertir la etiqueta a PDF: #{e.message}"
    end
  end
end
