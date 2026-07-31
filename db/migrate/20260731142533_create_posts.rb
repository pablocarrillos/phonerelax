class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.text :body
      t.string :image_url
      t.date :published_on

      t.timestamps
    end
    add_index :posts, :slug, unique: true
  end
end
