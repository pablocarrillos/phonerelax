# Histórico del presupuesto: creado, cambios de estado y de pago, albarán…
class CreateQuoteEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_events do |t|
      t.references :quote, null: false, foreign_key: true
      t.string :event, null: false
      t.timestamps
    end
  end
end
