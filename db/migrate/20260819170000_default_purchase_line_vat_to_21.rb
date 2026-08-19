class DefaultPurchaseLineVatTo21 < ActiveRecord::Migration[8.1]
  def up
    # el IVA habitual de las compras es el 21 %: las importaciones (0 %) son la
    # excepción y se marcan a mano en cada línea
    change_column_default :purchase_lines, :vat_rate, from: 0.0, to: 21.0
  end

  def down
    change_column_default :purchase_lines, :vat_rate, from: 21.0, to: 0.0
  end
end
