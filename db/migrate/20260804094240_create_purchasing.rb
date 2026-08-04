class CreatePurchasing < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :tax_id
      t.string :email
      t.string :phone
      t.string :website
      t.string :address
      t.string :country
      t.text :notes
      t.timestamps
    end

    create_table :purchases do |t|
      t.references :supplier, null: false, foreign_key: true
      t.string :reference
      t.date :ordered_on, null: false
      t.date :received_on
      t.decimal :shipping_cost, precision: 10, scale: 2, default: 0, null: false
      t.decimal :customs_cost, precision: 10, scale: 2, default: 0, null: false
      t.decimal :other_costs, precision: 10, scale: 2, default: 0, null: false
      t.text :notes
      t.timestamps
    end

    create_table :purchase_lines do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_cost, precision: 10, scale: 4, null: false
      t.timestamps
    end
  end
end
