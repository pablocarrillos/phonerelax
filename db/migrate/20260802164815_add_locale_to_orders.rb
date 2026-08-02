class AddLocaleToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :locale, :string, null: false, default: 'es'
  end
end
