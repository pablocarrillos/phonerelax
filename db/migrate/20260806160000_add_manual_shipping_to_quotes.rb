class AddManualShippingToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :manual_shipping, :boolean, default: false, null: false
  end
end
