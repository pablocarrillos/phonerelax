class AddSwedishTranslations < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :title_sv, :string
    add_column :posts, :excerpt_sv, :text
    add_column :posts, :body_sv, :text
    add_column :posts, :slug_sv, :string
    add_index :posts, :slug_sv, unique: true

    add_column :products, :name_sv, :string
    add_column :products, :description_sv, :text
  end
end
