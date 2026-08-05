class AddSoldToSamples < ActiveRecord::Migration[8.1]
  def change
    # Marca si la muestra acabó en venta (con independencia de si se devolvió).
    add_column :samples, :sold, :boolean, null: false, default: false
  end
end
