class AddShippingCountryToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :shipping_country, :string, default: "España", null: false
  end
end
