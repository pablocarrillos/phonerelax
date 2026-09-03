class DeliveryNotesDeliveryAddressAndSeries < ActiveRecord::Migration[8.1]
  def up
    # dirección de entrega separada de los datos fiscales del cliente
    add_column :delivery_notes, :delivery_address, :text
    # la serie pierde el prefijo ALBARAN (y pasa a ser editable en Datos de Empresa)
    change_column_default :company_settings, :delivery_note_series, from: "ALBARAN-PHONERELAX", to: "PHONERELAX"
    execute "UPDATE company_settings SET delivery_note_series = 'PHONERELAX' WHERE delivery_note_series = 'ALBARAN-PHONERELAX'"
    execute "UPDATE delivery_notes SET number = REPLACE(number, 'ALBARAN-PHONERELAX-', 'PHONERELAX-')"

    # regenera los albaranes existentes: datos fiscales del cliente actuales y
    # dirección de entrega (la del presupuesto o, en pedidos, la de envío)
    DeliveryNote.reset_column_information
    DeliveryNote.find_each do |note|
      quote = note.quote_id && Quote.includes(:client).find_by(id: note.quote_id)
      if quote
        client = quote.client
        note.update_columns(
          client_name: client.name, client_tax_id: client.tax_id.presence,
          client_email: client.email.presence, client_address: client.address,
          delivery_address: quote.delivery_address.presence || client.address
        )
      else
        note.update_columns(delivery_address: note.client_address)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
