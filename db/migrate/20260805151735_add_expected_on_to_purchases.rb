class AddExpectedOnToPurchases < ActiveRecord::Migration[8.1]
  def change
    add_column :purchases, :expected_on, :date
  end
end
