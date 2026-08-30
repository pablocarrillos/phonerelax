class AddPaymentReminderSentAtToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :payment_reminder_sent_at, :datetime
  end
end
