class AddShippingCostToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :shipping_cost, :decimal, precision: 8, scale: 2, default: 0, null: false
  end
end
