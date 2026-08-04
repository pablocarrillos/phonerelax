# Validación de identificadores fiscales: NIF, NIE y CIF españoles (con dígito
# de control) y NIF-IVA intracomunitario (formato por país). No consulta a
# ningún servicio externo; la comprobación VIES vive en Vies.
module TaxId
  DNI_LETTERS = "TRWAGMYFPDXBNJZSQVHLCKE".freeze
  CIF_FIRST   = "ABCDEFGHJNPQRSUVW".freeze

  # Formato del número de IVA por país de la UE (tras el código de país).
  EU_VAT_FORMATS = {
    "AT" => /\AU\d{8}\z/, "BE" => /\A0?\d{9}\z/, "BG" => /\A\d{9,10}\z/,
    "CY" => /\A\d{8}[A-Z]\z/, "CZ" => /\A\d{8,10}\z/, "DE" => /\A\d{9}\z/,
    "DK" => /\A\d{8}\z/, "EE" => /\A\d{9}\z/, "EL" => /\A\d{9}\z/, "ES" => /\A[A-Z0-9]\d{7}[A-Z0-9]\z/,
    "FI" => /\A\d{8}\z/, "FR" => /\A[A-Z0-9]{2}\d{9}\z/, "HR" => /\A\d{11}\z/,
    "HU" => /\A\d{8}\z/, "IE" => /\A\d{7}[A-Z]{1,2}\z|\A\d[A-Z]\d{5}[A-Z]\z/,
    "IT" => /\A\d{11}\z/, "LT" => /\A\d{9}(\d{3})?\z/, "LU" => /\A\d{8}\z/,
    "LV" => /\A\d{11}\z/, "MT" => /\A\d{8}\z/, "NL" => /\A\d{9}B\d{2}\z/,
    "PL" => /\A\d{10}\z/, "PT" => /\A\d{9}\z/, "RO" => /\A\d{2,10}\z/,
    "SE" => /\A\d{12}\z/, "SI" => /\A\d{8}\z/, "SK" => /\A\d{10}\z/
  }.freeze

  module_function

  # Deja el identificador en mayúsculas y sin espacios ni signos.
  def normalize(raw)
    raw.to_s.strip.upcase.gsub(/[\s.\-]/, "")
  end

  # :nif, :nie, :cif, :eu_vat o nil según qué sea (ya validado con su control).
  def kind(raw)
    id = normalize(raw)
    return :nif if nif?(id)
    return :nie if nie?(id)
    return :cif if cif?(id)
    return :eu_vat if eu_vat?(id)

    nil
  end

  def valid?(raw)
    !kind(raw).nil?
  end

  # ¿Es un NIF-IVA intracomunitario (empieza por código de país UE)? Útil para
  # decidir si conviene comprobarlo en VIES.
  def eu_vat?(raw)
    id = normalize(raw)
    cc = id[0, 2]
    fmt = EU_VAT_FORMATS[cc]
    return false unless fmt

    id[2..].to_s.match?(fmt)
  end

  # Separa un NIF-IVA en [código_país, número] (para consultarlo en VIES).
  def split_eu_vat(raw)
    id = normalize(raw)
    [ id[0, 2], id[2..].to_s ]
  end

  # --- Españoles ---

  def nif?(id)
    return false unless id.match?(/\A\d{8}[A-Z]\z/)

    DNI_LETTERS[id[0, 8].to_i % 23] == id[-1]
  end

  def nie?(id)
    return false unless id.match?(/\A[XYZ]\d{7}[A-Z]\z/)

    prefix = { "X" => "0", "Y" => "1", "Z" => "2" }[id[0]]
    DNI_LETTERS[(prefix + id[1, 7]).to_i % 23] == id[-1]
  end

  def cif?(id)
    return false unless id.match?(/\A[#{CIF_FIRST}]\d{7}[0-9A-J]\z/)

    digits = id[1, 7].chars.map(&:to_i)
    sum = digits.each_with_index.sum do |d, i|
      if i.even? # posiciones impares (1ª,3ª…): se duplican y se suman sus cifras
        doubled = d * 2
        doubled > 9 ? doubled - 9 : doubled
      else
        d
      end
    end
    control = (10 - (sum % 10)) % 10
    expected_digit = control.to_s
    expected_letter = "JABCDEFGHI"[control]
    # Según la primera letra el control es número, letra o cualquiera de los dos.
    case id[0]
    when "A", "B", "E", "H" then id[-1] == expected_digit
    when "K", "P", "Q", "S" then id[-1] == expected_letter
    else id[-1] == expected_digit || id[-1] == expected_letter
    end
  end
end
