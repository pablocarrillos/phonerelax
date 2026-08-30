# frozen_string_literal: true

class AddContactPhoneAndDeliveryAddressToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :contact_phone, :string
    add_column :quotes, :delivery_address, :text
  end
end
