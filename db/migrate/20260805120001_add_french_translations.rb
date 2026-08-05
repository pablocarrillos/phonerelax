class AddFrenchTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :title_fr, :string
    add_column :posts, :excerpt_fr, :text
    add_column :posts, :body_fr, :text
    add_column :posts, :slug_fr, :string
    add_index :posts, :slug_fr, unique: true

    add_column :products, :name_fr, :string
    add_column :products, :description_fr, :text
  end
end
