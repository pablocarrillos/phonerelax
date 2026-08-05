class AddQuoteStatusAndSampleQuote < ActiveRecord::Migration[8.1]
  def change
    # Estado del presupuesto: 0 abierto, 1 aprobado, 2 en pausa, 3 perdido.
    add_column :quotes, :status, :integer, null: false, default: 0
    # Una muestra enviada puede vincularse (opcionalmente) a un presupuesto.
    add_reference :samples, :quote, null: true, foreign_key: true
  end
end
