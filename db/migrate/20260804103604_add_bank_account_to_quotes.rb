class AddBankAccountToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :bank_account, :string
  end
end
