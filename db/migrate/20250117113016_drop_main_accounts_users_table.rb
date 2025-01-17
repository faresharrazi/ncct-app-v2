class DropMainAccountsUsersTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :main_accounts_users
  end
end
