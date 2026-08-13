# Contabilidad: datos de la empresa emisora (Drop Point Systems) con dos series
# de facturación (ventas web y presupuestos aprobados), y facturas con desglose
# de IVA y campos VERI*FACTU (integración calcada de gestion/agua).
class CreateAccounting < ActiveRecord::Migration[8.1]
  def up
    create_table :company_settings do |t|
      t.string :legal_name, null: false
      t.string :tax_id, null: false
      t.string :address
      t.string :city
      t.string :postal_code
      t.string :province
      t.string :country
      t.string :phone
      t.string :email
      t.string :web_series, default: "WEB", null: false
      t.integer :web_next_number, default: 1, null: false
      t.string :quote_series, default: "PRES", null: false
      t.integer :quote_next_number, default: 1, null: false
      t.boolean :verifactu_enabled, default: false, null: false
      t.string :verifactu_environment, default: "test", null: false
      t.string :verifactu_token
      t.timestamps
    end

    create_table :invoices do |t|
      t.string :number, null: false, index: { unique: true }
      t.string :kind, null: false # web / quote
      t.references :order, foreign_key: true, index: { unique: true }
      t.references :quote, foreign_key: true, index: { unique: true }
      t.date :issued_on, null: false
      t.string :client_name, null: false
      t.string :client_tax_id
      t.text :client_address
      t.string :client_email
      t.decimal :subtotal, precision: 10, scale: 2, default: 0, null: false
      t.decimal :vat_amount, precision: 10, scale: 2, default: 0, null: false
      t.decimal :total, precision: 10, scale: 2, default: 0, null: false
      t.json :vat_lines, default: [], null: false # [{"rate": 21.0, "base": 100.0}]
      t.string :verifactu_status, default: "disabled", null: false
      t.integer :verifactu_attempts, default: 0, null: false
      t.text :verifactu_error
      t.string :verifactu_huella
      t.text :verifactu_qr
      t.string :verifactu_url
      t.datetime :verifactu_sent_at
      t.datetime :emailed_at
      t.timestamps
    end

    create_table :invoice_lines do |t|
      t.references :invoice, null: false, foreign_key: true
      t.string :description, null: false
      t.decimal :quantity, precision: 8, scale: 2, default: 1, null: false
      t.decimal :unit_price, precision: 10, scale: 2, default: 0, null: false
      t.decimal :total, precision: 10, scale: 2, default: 0, null: false
      t.integer :position, default: 0, null: false
      t.timestamps
    end

    # Empresa emisora: los mismos datos de Drop Point Systems que usa gestion.
    CompanySetting.reset_column_information
    CompanySetting.create!(
      legal_name: "Drop Point Systems S.L.U.", tax_id: "B02631976",
      address: "C/ Carrasqueta 14 · P.I. Salinetas", city: "Petrer",
      postal_code: "03610", province: "Alicante", country: "España",
      phone: "+34 965 371 962", email: "contacto@drop-point.com"
    )
  end

  def down
    drop_table :invoice_lines
    drop_table :invoices
    drop_table :company_settings
  end
end
