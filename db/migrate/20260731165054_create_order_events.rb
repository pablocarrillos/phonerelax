class CreateOrderEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :order_events do |t|
      t.references :order, null: false, foreign_key: true
      t.string :event, null: false

      t.timestamps
    end

    # Histórico inicial: todos los pedidos existentes nacieron con el evento «creado».
    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO order_events (order_id, event, created_at, updated_at)
          SELECT id, 'creado', created_at, created_at FROM orders
        SQL
      end
    end
  end
end
