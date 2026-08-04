class CreateShippingRates < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_rates do |t|
      t.string :country, null: false
      t.decimal :base_cost, precision: 8, scale: 2, null: false
      t.timestamps
      t.index :country, unique: true
    end

    # Coste de transporte que añade cada unidad de este producto al envío.
    add_column :products, :shipping_unit_cost, :decimal, precision: 8, scale: 2, default: "1.0", null: false
  end
end
