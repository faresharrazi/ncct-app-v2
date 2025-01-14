class RenameTransactionToSubAccountTransaction < ActiveRecord::Migration[8.0]
  def change
    rename_table :transactions, :sub_account_transactions
  end
end
