class ChangeQuoteShippingCountryDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :quotes, :shipping_country, from: "España", to: "España (Península)"
  end
end
