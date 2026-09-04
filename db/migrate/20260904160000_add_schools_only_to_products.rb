# Productos que solo se venden y entregan a centros educativos, nunca a
# particulares (el imán de apertura): la tienda lo avisa en la ficha, el
# carrito y el pedido, en todos los idiomas.
class AddSchoolsOnlyToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :schools_only, :boolean, default: false, null: false
  end
end
