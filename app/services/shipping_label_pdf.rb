# Etiqueta de envío en A5 vertical para pegar en el paquete: logotipo de
# PHONE RELAX arriba, destinatario en grande y el remitente al pie. Va adjunta
# al correo interno de aviso de envío (OrderMailer#shipping_request).
class ShippingLabelPdf
  LOGO = Rails.root.join("public/images/site/phonerelax-logo-black.png")

  def self.render(order)
    new(order).render
  end

  def initialize(order)
    @order = order
    @setting = CompanySetting.current
  end

  def render
    doc = Prawn::Document.new(page_size: "A5", margin: 36)
    logo(doc)
    addressee(doc)
    sender(doc)
    doc.render
  end

  private

  def logo(doc)
    doc.image LOGO.to_s, width: 140, position: :center if LOGO.exist?
    doc.move_down 24
  end

  def addressee(doc)
    doc.text "ENTREGAR A:", size: 12, style: :bold
    doc.move_down 8
    doc.text @order.customer_name.to_s, size: 20, style: :bold
    address_lines.each { |line| doc.text line, size: 16 }
    doc.move_down 10
    doc.text "Tel. #{@order.phone}", size: 14 if @order.phone.present?
    doc.move_down 16
    doc.text "Pedido #{@order.number}", size: 11
  end

  def address_lines
    [ @order.address,
      [ @order.postal_code, @order.city ].compact_blank.join(" "),
      [ @order.province, @order.country ].compact_blank.join(" · ") ].compact_blank
  end

  def sender(doc)
    doc.bounding_box([ 0, 70 ], width: doc.bounds.width) do
      doc.stroke_horizontal_rule
      doc.move_down 8
      doc.text "Remitente: #{@setting.legal_name} (PHONE RELAX)", size: 9
      doc.text @setting.full_address.tr("\n", " · "), size: 9
      doc.text [ @setting.phone, @setting.email ].compact_blank.join(" · "), size: 9
    end
  end
end
