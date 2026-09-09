class AddSimplifiedAndRectificationInvoices < ActiveRecord::Migration[8.1]
  def change
    # Serie de facturas SIMPLIFICADAS (ventas web sin datos fiscales) y de
    # RECTIFICATIVAS. Ambas continuas (6 dígitos, sin reinicio anual), como los
    # albaranes.
    add_column :company_settings, :simplified_series, :string, null: false, default: "4"
    add_column :company_settings, :simplified_next_number, :integer, null: false, default: 1
    add_column :company_settings, :rectification_series, :string, null: false, default: "R"
    add_column :company_settings, :rectification_next_number, :integer, null: false, default: 1

    # simplified: la factura es simplificada (sin datos fiscales del cliente).
    # rectifies_invoice_id: si está, es una rectificativa de esa factura.
    add_column :invoices, :simplified, :boolean, null: false, default: false
    add_reference :invoices, :rectifies_invoice, null: true, foreign_key: { to_table: :invoices }
  end
end
