class CreateOntimeShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :ontime_shipments do |t|
      # Asociación polimórfica: un envío cuelga de un pedido (Order) o de un
      # presupuesto (Quote).
      t.references :shippable, polymorphic: true, null: false

      t.string  :admission_code, null: false   # nuestra referencia única en Ontime
      t.string  :tracking_number               # nº de seguimiento que devuelve Ontime
      t.string  :postal_code, null: false       # CP de destino (lo exigen estado/etiqueta)
      t.string  :service_code, null: false, default: "24" # productCode Ontime (24 = XS)
      t.string  :recipient_name

      t.integer :parcel_count, null: false, default: 1
      t.decimal :weight, precision: 8, scale: 2, null: false, default: 1.0

      t.string   :status                        # último estado legible conocido
      t.string   :status_code                   # código de estado de Ontime (si lo da)
      t.integer  :event_count, null: false, default: 0
      t.boolean  :delivered, null: false, default: false
      t.datetime :last_polled_at
      t.jsonb    :last_response, null: false, default: {} # última respuesta cruda de Ontime

      t.timestamps
    end

    add_index :ontime_shipments, :admission_code, unique: true
    add_index :ontime_shipments, :tracking_number
    add_index :ontime_shipments, :delivered
  end
end
