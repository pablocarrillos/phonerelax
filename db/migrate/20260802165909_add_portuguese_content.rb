class AddPortugueseContent < ActiveRecord::Migration[8.1]
  def change
    # Traducciones al portugués. Vacías = se muestra el contenido en español.
    add_column :products, :name_pt, :string
    add_column :products, :description_pt, :text

    add_column :posts, :title_pt, :string
    add_column :posts, :excerpt_pt, :text
    add_column :posts, :body_pt, :text
  end
end
