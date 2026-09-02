class CreateEmailTemplates < ActiveRecord::Migration[8.1]
  def change
    # apellidos separados del nombre y asunto del correo original del lead
    # (la respuesta desde Gmail usa ese mismo asunto)
    add_column :leads, :last_name, :string
    add_column :leads, :email_subject, :string

    # plantillas de respuesta estándar que se cargan en la ventana de redactar
    # de Gmail con las variables del lead sustituidas (copiado de gestion)
    create_table :email_templates do |t|
      t.string :name, null: false
      t.string :subject
      t.text :body, null: false
      t.timestamps
    end
    add_index :email_templates, :name, unique: true
  end
end
