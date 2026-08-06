class CreateImageComments < ActiveRecord::Migration[8.1]
  def change
    create_table :image_comments do |t|
      t.string :path, null: false
      t.string :comment
      t.timestamps
    end
    add_index :image_comments, :path, unique: true
  end
end
