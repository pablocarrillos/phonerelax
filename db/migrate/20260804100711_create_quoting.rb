class CreateQuoting < ActiveRecord::Migration[8.1]
  def change
    # Clientes de presupuesto (datos fiscales)
    create_table :clients do |t|
      t.string :name, null: false
      t.string :tax_id
      t.text :address
      t.string :email
      t.string :phone
      t.text :notes
      t.timestamps
    end

    # Escalado de precios por producto (precios sin IVA por tramos de unidades)
    create_table :price_tiers do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :min_units, null: false
      t.decimal :unit_price, precision: 10, scale: 4, null: false
      t.timestamps
      t.index [ :product_id, :min_units ], unique: true
    end

    # Presupuestos
    create_table :quotes do |t|
      t.references :client, null: false, foreign_key: true
      t.string :number, null: false
      t.date :issued_on, null: false
      t.date :valid_until
      t.decimal :shipping_cost, precision: 10, scale: 2, default: 0, null: false
      t.decimal :vat_rate, precision: 5, scale: 2, default: "21.0", null: false
      t.string :payment_terms
      t.string :delivery_terms
      t.text :notes
      t.timestamps
      t.index :number, unique: true
    end

    create_table :quote_lines do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :product, foreign_key: true # opcional: líneas libres
      t.string :description, null: false
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 4, null: false
      t.decimal :vat_rate, precision: 5, scale: 2, default: "21.0", null: false
      t.timestamps
    end
  end
end
