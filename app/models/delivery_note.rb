# Albarán numerado (serie ALBARAN-PHONERELAX) generado desde un pedido web o
# desde un presupuesto. Copia el cliente y las líneas SIN ningún precio: el
# albarán documenta la entrega, no el cobro. A diferencia de la factura, se
# puede editar después de emitirse: el número se conserva siempre, pero los
# datos (cliente, líneas, comentarios) son modificables.
class DeliveryNote < ApplicationRecord
  belongs_to :order, optional: true
  belongs_to :quote, optional: true
  has_many :lines, -> { order(:position, :id) },
           class_name: "DeliveryNoteLine", dependent: :destroy, inverse_of: :delivery_note

  validates :number, presence: true, uniqueness: true
  validates :client_name, :issued_on, presence: true

  # edición de líneas desde el formulario del albarán; las filas nuevas sin
  # descripción se ignoran (huecos del formulario)
  accepts_nested_attributes_for :lines, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["id"].blank? && attrs["description"].blank? }

  # Genera (idempotente) el albarán de un pedido web: si ya existe se devuelve
  # sin consumir un número nuevo de la serie.
  def self.issue_for_order!(order)
    existing = find_by(order: order)
    return existing if existing

    transaction do
      shipping_address = [ order.address, [ order.postal_code, order.city ].compact_blank.join(" "),
                           [ order.province, order.country ].compact_blank.join(" · ") ].compact_blank.join("\n")
      note = create!(
        number: CompanySetting.current.take_delivery_note_number!,
        order: order, issued_on: Date.current,
        client_name: order.customer_name, client_tax_id: order.tax_id.presence,
        client_email: order.email,
        client_address: shipping_address, delivery_address: shipping_address
      )
      order.order_lines.each_with_index do |line, index|
        note.lines.create!(description: line.product.name, quantity: line.quantity, position: index)
      end
      note
    end
  end

  # Genera (idempotente) el albarán de un presupuesto. Usa la dirección de
  # entrega del presupuesto si la tiene; si no, la del cliente.
  def self.issue_for_quote!(quote)
    existing = find_by(quote: quote)
    return existing if existing

    client = quote.client
    transaction do
      note = create!(
        number: CompanySetting.current.take_delivery_note_number!,
        quote: quote, issued_on: Date.current,
        client_name: client.name, client_tax_id: client.tax_id.presence,
        client_email: client.email.presence,
        client_address: client.address,
        delivery_address: quote.delivery_address.presence || client.address
      )
      quote.active_lines.each_with_index do |line, index|
        note.lines.create!(description: line.description, quantity: line.quantity, position: index)
      end
      note
    end
  end

  # Datos para el PDF (formato de la factura, sin ningún precio).
  def pdf_data
    {
      number: number, issued_on: issued_on,
      client_name: client_name, client_tax_id: client_tax_id, client_address: client_address,
      delivery_address: delivery_address,
      lines: lines.map { |l| { description: l.description, quantity: l.quantity } },
      comments: comments
    }
  end

  # "pedido WEB-..." o "presupuesto PRES-...", para avisos y enlaces.
  def source_label
    order ? "el pedido #{order.number}" : "el presupuesto #{quote&.number}"
  end
end
