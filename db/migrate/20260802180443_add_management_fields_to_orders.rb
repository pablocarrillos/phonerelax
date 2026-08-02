class AddManagementFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :tracking_number, :string
    add_column :orders, :tracking_carrier, :string
    add_column :orders, :admin_notes, :text
    add_column :orders, :paid_manually, :boolean, null: false, default: false
  end
end
