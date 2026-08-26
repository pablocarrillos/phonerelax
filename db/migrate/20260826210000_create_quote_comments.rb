# frozen_string_literal: true

class CreateQuoteComments < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_comments do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
  end
end
