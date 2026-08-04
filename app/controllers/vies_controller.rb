# Comprobación en vivo de un NIF-IVA europeo contra VIES para el checkout.
# Devuelve JSON { valid: true|false|null, name:, reason: } sin bloquear si el
# servicio de la Comisión no responde.
class ViesController < ApplicationController
  allow_unauthenticated_access

  def check
    render json: Vies.check(params[:vat].to_s)
  end
end
