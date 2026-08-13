# IVA soportado de cada línea de compra (0 % en importaciones, 21/10 % en
# proveedores nacionales): permite calcular el IVA total de la factura. El
# coste real por producto sigue siendo sin IVA (es deducible, no un coste).
class AddVatRateToPurchaseLines < ActiveRecord::Migration[8.1]
  def change
    add_column :purchase_lines, :vat_rate, :decimal, precision: 5, scale: 2, default: "0.0", null: false
  end
end
