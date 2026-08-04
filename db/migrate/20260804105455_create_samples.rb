class CreateSamples < ActiveRecord::Migration[8.1]
  def change
    create_table :samples do |t|
      t.string :organization, null: false
      t.string :contact_name
      t.string :email
      t.date :sent_on
      t.date :returned_on
      t.text :notes
      t.timestamps
    end

    create_table :sample_lines do |t|
      t.references :sample, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
  end
end
