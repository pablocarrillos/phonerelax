class CreatePackItems < ActiveRecord::Migration[8.1]
  def change
    # Un producto puede ser un "pack" compuesto por varias unidades de otros
    # productos; su precio se calcula con el escalado de cada componente.
    add_column :products, :pack, :boolean, null: false, default: false

    create_table :pack_items do |t|
      t.references :pack, null: false, foreign_key: { to_table: :products }
      t.references :component, null: false, foreign_key: { to_table: :products }
      t.integer :quantity, null: false, default: 1
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
