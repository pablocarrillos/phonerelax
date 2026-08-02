class CreateQuoteRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_requests do |t|
      t.string :name
      t.string :organization
      t.string :email
      t.string :phone
      t.string :sector
      t.integer :units
      t.text :message

      t.timestamps
    end
  end
end
