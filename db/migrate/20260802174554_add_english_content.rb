class AddEnglishContent < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :name_en, :string
    add_column :products, :description_en, :text

    add_column :posts, :title_en, :string
    add_column :posts, :excerpt_en, :text
    add_column :posts, :body_en, :text
  end
end
