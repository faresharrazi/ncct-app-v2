class ChangeSubAccountIdToBeNullableInTransactions < ActiveRecord::Migration[7.0]
  def change
    change_column_null :transactions, :sub_account_id, true
  end
end