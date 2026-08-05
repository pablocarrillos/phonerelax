class AddGermanTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :title_de, :string
    add_column :posts, :excerpt_de, :text
    add_column :posts, :body_de, :text
    add_column :posts, :slug_de, :string
    add_index :posts, :slug_de, unique: true

    add_column :products, :name_de, :string
    add_column :products, :description_de, :text
  end
end
