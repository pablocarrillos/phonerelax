# frozen_string_literal: true

class AddContactToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :contact_name, :string
    add_column :quotes, :contact_email, :string
  end
end
