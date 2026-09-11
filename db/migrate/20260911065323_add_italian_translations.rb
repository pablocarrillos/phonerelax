class AddItalianTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :name_it, :string
    add_column :products, :description_it, :text

    add_column :posts, :title_it, :string
    add_column :posts, :excerpt_it, :text
    add_column :posts, :body_it, :text
    add_column :posts, :slug_it, :string
    add_index :posts, :slug_it, unique: true
  end
end
