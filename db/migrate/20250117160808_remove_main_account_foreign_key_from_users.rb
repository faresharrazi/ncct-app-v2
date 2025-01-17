class RemoveMainAccountForeignKeyFromUsers < ActiveRecord::Migration[8.0]
  def change
change_column_null :users, :main_account_id, true
  end
end
