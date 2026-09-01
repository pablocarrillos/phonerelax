class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    # Leads comerciales (colegios, empresas…), copiados del sistema de gestion:
    # varios emails por lead, historial de gestiones (la última fija el estado
    # y el presupuesto del lead) y vínculos con muestras y presupuestos.
    create_table :leads do |t|
      t.string :name, null: false
      t.string :phone
      t.string :city
      t.string :origin
      t.string :status, null: false, default: "1er contacto"
      t.boolean :to_answer, null: false, default: false
      t.decimal :budget_amount, precision: 12, scale: 2
      t.bigint :client_id # se enlaza al añadir los datos fiscales
      t.timestamps
    end
    add_index :leads, :name
    add_index :leads, :status
    add_index :leads, :client_id

    create_table :lead_emails do |t|
      t.references :lead, null: false, foreign_key: true
      t.string :email, null: false
      t.timestamps
    end
    add_index :lead_emails, [ :lead_id, :email ], unique: true

    create_table :lead_managements do |t|
      t.references :lead, null: false, foreign_key: true
      t.string :status, null: false
      t.string :channel, null: false
      t.datetime :happened_at, null: false
      t.text :action, null: false
      t.decimal :budget_amount, precision: 12, scale: 2
      t.timestamps
    end

    # muestras y presupuestos generados desde un lead
    add_column :samples, :lead_id, :bigint
    add_index :samples, :lead_id
    add_column :quotes, :lead_id, :bigint
    add_index :quotes, :lead_id
  end
end
