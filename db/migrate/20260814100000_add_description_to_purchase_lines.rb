# Una línea de compra puede ser un concepto libre (maquinaria, cajas…) en vez
# de un producto de la tienda: no suma stock ni entra en el coste real.
class AddDescriptionToPurchaseLines < ActiveRecord::Migration[8.1]
  def change
    add_column :purchase_lines, :description, :string
    change_column_null :purchase_lines, :product_id, true
  end
end
