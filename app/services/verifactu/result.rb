# frozen_string_literal: true

module Verifactu
  # Resultado normalizado de una llamada a la API de TICKETBAIWS.
  Result = Struct.new(:ok, :huella, :qr, :url, :message, keyword_init: true) do
    def ok? = ok
  end
end
