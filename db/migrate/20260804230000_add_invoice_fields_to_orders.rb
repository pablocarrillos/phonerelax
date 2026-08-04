class AddInvoiceFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    # El cliente puede pedir factura y, si lo hace, aporta sus datos fiscales.
    add_column :orders, :needs_invoice, :boolean, null: false, default: false
    add_column :orders, :tax_name, :string
    add_column :orders, :tax_id, :string
    add_column :orders, :tax_address, :string
    add_column :orders, :tax_city, :string
    add_column :orders, :tax_postal_code, :string
    add_column :orders, :tax_province, :string
    add_column :orders, :tax_country, :string
    # Resultado de la comprobación VIES del NIF-IVA intracomunitario (si aplica).
    add_column :orders, :vies_valid, :boolean
    # Tratamiento de IVA aplicado (hoy siempre con IVA; los interruptores de
    # exención viven en el modelo y se activan al estar de alta en ROI/OSS).
    add_column :orders, :vat_exempt, :boolean, null: false, default: false
    add_column :orders, :vat_exempt_reason, :string
  end
end
