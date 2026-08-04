class AddCurrencyToPurchases < ActiveRecord::Migration[8.1]
  def change
    # Moneda de los importes de la compra (EUR o USD).
    add_column :purchases, :currency, :string, null: false, default: "EUR"
    # Fecha de la factura: se usa para consultar el tipo de cambio de ese día.
    add_column :purchases, :invoice_date, :date
    # Tipo de cambio USD→EUR (euros por 1 USD) fijado en la fecha de factura.
    add_column :purchases, :exchange_rate, :decimal, precision: 12, scale: 6
  end
end
