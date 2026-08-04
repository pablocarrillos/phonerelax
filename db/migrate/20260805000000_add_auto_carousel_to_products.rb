class AddAutoCarouselToProducts < ActiveRecord::Migration[8.1]
  def change
    # Muestra la galería del producto como carrusel automático (sin controles)
    # en vez de la imagen fija con miniaturas.
    add_column :products, :auto_carousel, :boolean, null: false, default: false
  end
end
