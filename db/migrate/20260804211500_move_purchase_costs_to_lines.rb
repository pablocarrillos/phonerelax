class MovePurchaseCostsToLines < ActiveRecord::Migration[8.1]
  def change
    # Los costes de transporte, aduanas y otros pasan de la compra a cada línea.
    add_column :purchase_lines, :shipping_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :purchase_lines, :customs_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :purchase_lines, :other_costs, :decimal, precision: 10, scale: 2, null: false, default: 0

    remove_column :purchases, :shipping_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
    remove_column :purchases, :customs_cost, :decimal, precision: 10, scale: 2, null: false, default: 0
    remove_column :purchases, :other_costs, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
