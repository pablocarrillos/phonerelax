# Una línea de compra puede imputarse a un presupuesto de cliente concreto
# (material comprado para ese cliente): así el presupuesto conoce sus costes.
class AddQuoteToPurchaseLines < ActiveRecord::Migration[8.1]
  def change
    add_reference :purchase_lines, :quote, foreign_key: true
  end
end
