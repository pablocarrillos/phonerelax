require "net/http"
require "json"

# Comprueba un NIF-IVA intracomunitario contra VIES (servicio oficial de la
# Comisión Europea). Devuelve un hash con :ok (si el servicio respondió),
# :valid (true/false/nil) y, si es válido, :name y :address del titular.
module Vies
  API = "https://ec.europa.eu/taxation_customs/vies/rest-api/ms".freeze

  module_function

  def check(raw)
    country, number = TaxId.split_eu_vat(raw)
    return { ok: true, valid: false, reason: "format" } unless TaxId.eu_vat?(raw)

    uri = URI("#{API}/#{country}/vat/#{number}")
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 6) do |http|
      http.get(uri.request_uri, "Accept" => "application/json")
    end
    return { ok: false, valid: nil, reason: "unavailable" } unless res.is_a?(Net::HTTPSuccess)

    data = JSON.parse(res.body)
    { ok: true, valid: data["isValid"] == true,
      name: data["name"].to_s.strip.presence, address: data["address"].to_s.strip.presence }
  rescue StandardError
    # Si VIES no responde no bloqueamos la compra: se guarda como "no comprobado".
    { ok: false, valid: nil, reason: "unavailable" }
  end
end
