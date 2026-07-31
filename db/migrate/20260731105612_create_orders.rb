class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :number, null: false, index: { unique: true }
      t.string :customer_name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :address
      t.integer :status, default: 0, null: false
      t.integer :payment_status, default: 0, null: false
      t.string :stripe_session_id
      t.decimal :total, precision: 8, scale: 2

      t.timestamps
    end
  end
end
