class RenameTransactionTypeToTransactionKind < ActiveRecord::Migration[8.0]
  def change
    rename_column :transactions, :transaction_type, :transaction_kind
  end
end
