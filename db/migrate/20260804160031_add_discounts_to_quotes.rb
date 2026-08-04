class AddDiscountsToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :discount_percent, :decimal, precision: 5, scale: 2, default: 0, null: false
    add_column :quote_lines, :discount_percent, :decimal, precision: 5, scale: 2, default: 0, null: false
  end
end
