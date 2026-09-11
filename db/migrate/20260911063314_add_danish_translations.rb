class AddDanishTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :name_da, :string
    add_column :products, :description_da, :text

    add_column :posts, :title_da, :string
    add_column :posts, :excerpt_da, :text
    add_column :posts, :body_da, :text
    add_column :posts, :slug_da, :string
    add_index :posts, :slug_da, unique: true
  end
end
