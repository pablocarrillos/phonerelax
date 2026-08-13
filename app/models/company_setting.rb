# Datos de la empresa emisora de las facturas (Drop Point Systems) y sus dos
# series de facturación: WEB (ventas de la tienda) y PRES (presupuestos
# aprobados). Fila única, como los ajustes de gestion.
class CompanySetting < ApplicationRecord
  KINDS = { "web" => :web, "quote" => :quote }.freeze

  validates :legal_name, :tax_id, :web_series, :quote_series, presence: true
  validates :web_next_number, :quote_next_number,
            numericality: { only_integer: true, greater_than: 0 }

  def self.current
    first || create!(legal_name: "Drop Point Systems S.L.U.", tax_id: "B02631976")
  end

  def preview_number(kind)
    format_number(series_for(kind), next_number_for(kind))
  end

  # Consume un número de la serie y lo devuelve (con lock, para no repetirlo).
  def take_number!(kind)
    column = kind == "quote" ? :quote_next_number : :web_next_number
    with_lock do
      number = format_number(series_for(kind), self[column])
      update!(column => self[column] + 1)
      number
    end
  end

  def series_for(kind)
    kind == "quote" ? quote_series : web_series
  end

  def next_number_for(kind)
    kind == "quote" ? quote_next_number : web_next_number
  end

  def full_address
    [ address, [ postal_code, city ].compact_blank.join(" "),
      [ province, country ].compact_blank.join(" · ") ].compact_blank.join("\n")
  end

  # --- VERI*FACTU (TICKETBAIWS, misma integración que gestion y agua) ---
  VERIFACTU_BASE_URLS = {
    "test" => "https://api-test.ticketbaiws.eus",
    "production" => "https://api.ticketbaiws.eus"
  }.freeze

  def verifactu_base_url
    VERIFACTU_BASE_URLS[verifactu_environment] || VERIFACTU_BASE_URLS["test"]
  end

  def verifactu_configured?
    verifactu_enabled? && verifactu_token.present? && tax_id.present?
  end

  private

  def format_number(series, number)
    "#{series}-#{format('%04d', number)}"
  end
end
