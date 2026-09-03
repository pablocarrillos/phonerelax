# Datos de la empresa emisora de las facturas (Drop Point Systems) y sus dos
# series de facturación: WEB (ventas de la tienda) y PRES (presupuestos
# aprobados). Fila única, como los ajustes de gestion.
class CompanySetting < ApplicationRecord
  KINDS = { "web" => :web, "quote" => :quote }.freeze

  # cifrado en BD (ver initializer active_record_encryption)
  encrypts :verifactu_token

  validates :legal_name, :tax_id, :web_series, :quote_series, :delivery_note_series, presence: true
  validates :web_next_number, :quote_next_number, :delivery_note_next_number,
            numericality: { only_integer: true, greater_than: 0 }

  def self.current
    first || create!(legal_name: "Drop Point Systems S.L.U.", tax_id: "B02631976")
  end

  # Números tipo WEB26-0001: serie + dos dígitos del año en curso + secuencial.
  # Al cambiar de año, cada serie reinicia su numeración en 0001.
  def preview_number(kind)
    format_number(series_for(kind), series_year_stale?(kind) ? 1 : next_number_for(kind))
  end

  # Consume un número de la serie y lo devuelve (con lock, para no repetirlo).
  def take_number!(kind)
    number_column = kind == "quote" ? :quote_next_number : :web_next_number
    year_column = kind == "quote" ? :quote_series_year : :web_series_year
    with_lock do
      update!(year_column => Date.current.year, number_column => 1) if self[year_column] != Date.current.year
      number = format_number(series_for(kind), self[number_column])
      update!(number_column => self[number_column] + 1)
      number
    end
  end

  # Consume un número de la serie de albaranes y lo devuelve (con lock). A
  # diferencia de las facturas, la numeración es continua: sin año y sin
  # reinicio anual. El prefijo se cambia en Datos de Empresa.
  def take_delivery_note_number!
    with_lock do
      number = "#{delivery_note_series}-#{format('%06d', delivery_note_next_number)}"
      update!(delivery_note_next_number: delivery_note_next_number + 1)
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

  def series_year_stale?(kind)
    (kind == "quote" ? quote_series_year : web_series_year) != Date.current.year
  end

  def format_number(series, number)
    "#{series}#{Date.current.strftime('%y')}-#{format('%04d', number)}"
  end
end
