class AddRefundsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :refunded_amount, :decimal, precision: 8, scale: 2, default: 0, null: false
    add_column :orders, :stripe_payment_intent_id, :string
  end
end
