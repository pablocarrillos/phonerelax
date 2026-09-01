class CreateDeliveryNotes < ActiveRecord::Migration[8.1]
  def change
    # Albaranes numerados (serie ALBARAN-PHONERELAX) generados desde pedidos web
    # o presupuestos. Sin precios: documentan la entrega, no el cobro. Editables
    # tras emitirse (el número se conserva).
    create_table :delivery_notes do |t|
      t.string :number, null: false
      t.bigint :order_id
      t.bigint :quote_id
      t.date :issued_on, null: false
      t.string :client_name, null: false
      t.string :client_tax_id
      t.string :client_email
      t.text :client_address
      t.text :comments
      t.timestamps
    end
    add_index :delivery_notes, :number, unique: true
    add_index :delivery_notes, :order_id, unique: true
    add_index :delivery_notes, :quote_id, unique: true

    create_table :delivery_note_lines do |t|
      t.references :delivery_note, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :quantity, precision: 8, scale: 2, default: 1, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    # la serie sigue la numeración que se venía usando a mano: el próximo es el 32
    add_column :company_settings, :delivery_note_series, :string, default: "ALBARAN-PHONERELAX", null: false
    add_column :company_settings, :delivery_note_next_number, :integer, default: 32, null: false
  end
end
