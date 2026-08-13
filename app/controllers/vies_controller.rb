# Comprobación en vivo de un NIF-IVA europeo contra VIES para el checkout.
# Devuelve JSON { valid: true|false|null, name:, reason: } sin bloquear si el
# servicio de la Comisión no responde.
class ViesController < ApplicationController
  allow_unauthenticated_access
  # Cada comprobación lanza una petición al servicio de la Comisión: límite por
  # IP para que nadie lo use de pasarela de consultas masivas.
  rate_limit to: 30, within: 10.minutes,
             with: -> { render json: { valid: nil, reason: "rate_limited" }, status: :too_many_requests }

  def check
    render json: Vies.check(params[:vat].to_s)
  end
end
