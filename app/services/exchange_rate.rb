require "net/http"
require "json"

# Tipo de cambio USD→EUR (euros por 1 dólar) en una fecha dada, usando la API
# pública de frankfurter.dev (tipos de referencia del BCE; para fines de semana
# o festivos devuelve el del día hábil anterior más cercano).
module ExchangeRate
  API = "https://api.frankfurter.dev/v1".freeze

  # Devuelve el tipo EUR por 1 USD en la fecha (BigDecimal) o nil si falla.
  def self.usd_to_eur(date)
    uri = URI("#{API}/#{date.to_date.iso8601}?base=USD&symbols=EUR")
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      http.get(uri.request_uri)
    end
    return nil unless res.is_a?(Net::HTTPSuccess)
    rate = JSON.parse(res.body).dig("rates", "EUR")
    rate && BigDecimal(rate.to_s)
  rescue StandardError
    nil
  end
end
