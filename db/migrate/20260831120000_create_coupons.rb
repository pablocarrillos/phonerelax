# frozen_string_literal: true

class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.boolean :enabled, null: false, default: true
      t.date :starts_on
      t.date :ends_on
      t.integer :max_uses
      t.integer :uses_count, null: false, default: 0
      t.decimal :discount_percent, precision: 5, scale: 2
      t.decimal :discount_amount, precision: 8, scale: 2
      t.string :notify_emails
      t.timestamps
    end
    add_index :coupons, "LOWER(code)", unique: true, name: "index_coupons_on_lower_code"

    add_reference :orders, :coupon, foreign_key: true
    add_column :orders, :coupon_code, :string
    add_column :orders, :coupon_discount, :decimal, precision: 8, scale: 2, default: "0.0", null: false
  end
end
