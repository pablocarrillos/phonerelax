class AddVatPercentageToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :vat_percentage, :decimal, precision: 5, scale: 2, default: 21, null: false
  end
end
