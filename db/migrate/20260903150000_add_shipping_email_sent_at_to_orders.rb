class AddShippingEmailSentAtToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :shipping_email_sent_at, :datetime
  end
end
