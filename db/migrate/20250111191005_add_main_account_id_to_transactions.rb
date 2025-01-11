class AddMainAccountIdToTransactions < ActiveRecord::Migration[7.0]
  def change
    add_reference :transactions, :main_account, foreign_key: true
  end
end

