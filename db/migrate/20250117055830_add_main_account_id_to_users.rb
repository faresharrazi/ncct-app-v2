class AddMainAccountIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :main_account_id, :integer
    add_index :users, :main_account_id
  end
end
