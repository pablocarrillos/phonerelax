class AddInternalDescriptionToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :internal_description, :string
  end
end
