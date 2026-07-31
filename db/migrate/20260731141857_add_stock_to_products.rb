class AddStockToProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :stock, :integer, default: 0, null: false
    # Stock inicial provisional para el catálogo existente: ajusta las cifras reales en el admin.
    execute 'UPDATE products SET stock = 100'
  end

  def down
    remove_column :products, :stock
  end
end
