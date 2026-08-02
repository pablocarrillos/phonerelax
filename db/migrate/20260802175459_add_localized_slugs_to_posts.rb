class AddLocalizedSlugsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :slug_pt, :string
    add_column :posts, :slug_en, :string
    add_index :posts, :slug_pt, unique: true
    add_index :posts, :slug_en, unique: true
  end
end
