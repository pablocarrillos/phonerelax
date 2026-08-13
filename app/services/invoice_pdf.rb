# PDF de una factura (o de su previsualización) con prawn: cabecera de la
# empresa, datos del cliente, líneas, desglose de IVA y, si la factura está
# registrada en VeriFactu, su QR y huella.
class InvoicePdf
  EUR = ->(v) { "#{format('%.2f', v)} €" }

  # data: hash con las claves de una factura (number, issued_on, client_*,
  # lines [{description:, quantity:, unit_price:, total:}], vat_lines, totales,
  # verifactu_qr/huella/url opcionales). Invoice#pdf_data lo produce; para la
  # previsualización se construye sin guardar nada.
  def self.render(data)
    new(data).render
  end

  def initialize(data)
    @data = data
    @setting = CompanySetting.current
  end

  def render
    doc = Prawn::Document.new(page_size: "A4", margin: 40)
    header(doc)
    client_box(doc)
    lines_table(doc)
    totals(doc)
    verifactu(doc)
    footer(doc)
    doc.render
  end

  private

  def header(doc)
    doc.text @setting.legal_name, size: 16, style: :bold
    doc.text "CIF #{@setting.tax_id}", size: 9
    doc.text @setting.full_address.tr("\n", " · "), size: 9
    doc.text [ @setting.phone, @setting.email ].compact_blank.join(" · "), size: 9
    doc.move_down 6
    title = @data[:provisional] ? "FACTURA (PREVISUALIZACIÓN)" : "FACTURA #{@data[:number]}"
    doc.text title, size: 13, style: :bold, align: :right
    doc.text "Fecha: #{@data[:issued_on].strftime('%d/%m/%Y')}", size: 9, align: :right
    doc.stroke_horizontal_rule
    doc.move_down 10
  end

  def client_box(doc)
    doc.text "Cliente", size: 9, style: :bold
    doc.text @data[:client_name].to_s, size: 10
    doc.text "NIF: #{@data[:client_tax_id]}", size: 9 if @data[:client_tax_id].present?
    doc.text @data[:client_address].to_s.tr("\n", " · "), size: 9 if @data[:client_address].present?
    doc.move_down 12
  end

  def lines_table(doc)
    rows = [ %w[Descripción Uds. Precio Total] ]
    @data[:lines].each do |line|
      rows << [ line[:description], line[:quantity].to_s,
                EUR.call(line[:unit_price]), EUR.call(line[:total]) ]
    end
    doc.table(rows, header: true, width: doc.bounds.width,
                    column_widths: { 1 => 45, 2 => 75, 3 => 75 },
                    cell_style: { size: 9, borders: [ :bottom ], border_color: "DDDDDD", padding: 5 }) do
      row(0).font_style = :bold
      columns(1..3).align = :right
    end
    doc.move_down 10
  end

  def totals(doc)
    vat_detail = @data[:vat_lines].map(&:stringify_keys)
                                  .map { |l| "IVA #{l['rate'].to_f.round}%: base #{EUR.call(l['base'])}" }.join(" · ")
    doc.text vat_detail, size: 8, align: :right if vat_detail.present?
    doc.text "Base imponible: #{EUR.call(@data[:subtotal])}", size: 10, align: :right
    doc.text "IVA: #{EUR.call(@data[:vat_amount])}", size: 10, align: :right
    doc.text "TOTAL: #{EUR.call(@data[:total])}", size: 12, style: :bold, align: :right
    doc.move_down 14
  end

  def verifactu(doc)
    return if @data[:verifactu_qr].blank?

    doc.image StringIO.new(Base64.decode64(@data[:verifactu_qr])), width: 90, height: 90
    doc.text "Factura verificable en la sede electrónica de la AEAT (VERI*FACTU).", size: 7
    doc.text "Huella: #{@data[:verifactu_huella]}", size: 7 if @data[:verifactu_huella].present?
    doc.text @data[:verifactu_url].to_s, size: 6 if @data[:verifactu_url].present?
  end

  def footer(doc)
    doc.number_pages "#{@setting.legal_name} · #{@setting.tax_id}",
                     at: [ 0, -20 ], align: :center, size: 7
  end
end
