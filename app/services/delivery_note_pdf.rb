# PDF de un albarán con prawn: mismo formato que la factura (cabecera de la
# empresa, datos del cliente y tabla de líneas) pero SIN ningún precio: solo
# descripción y unidades, más los comentarios si los hay.
class DeliveryNotePdf
  # data: hash que produce DeliveryNote#pdf_data (number, issued_on, client_*,
  # lines [{description:, quantity:}], comments).
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
    comments(doc)
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
    doc.text "ALBARÁN #{@data[:number]}", size: 13, style: :bold, align: :right
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
    rows = [ %w[Descripción Uds.] ]
    @data[:lines].each do |line|
      rows << [ line[:description], line[:quantity].to_s ]
    end
    doc.table(rows, header: true, width: doc.bounds.width,
                    column_widths: { 1 => 60 },
                    cell_style: { size: 9, borders: [ :bottom ], border_color: "DDDDDD", padding: 5 }) do
      row(0).font_style = :bold
      columns(1).align = :right
    end
    doc.move_down 10
  end

  def comments(doc)
    return if @data[:comments].blank?

    doc.text "Comentarios", size: 9, style: :bold
    doc.text @data[:comments].to_s, size: 9
    doc.move_down 10
  end

  def footer(doc)
    doc.number_pages "#{@setting.legal_name} · #{@setting.tax_id}",
                     at: [ 0, -20 ], align: :center, size: 7
  end
end
