class ChangeTransactionKindToString < ActiveRecord::Migration[8.0]
  def change
    change_column :transactions, :transaction_kind, :string
  end
end
