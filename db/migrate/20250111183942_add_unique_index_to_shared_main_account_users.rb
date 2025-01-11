class AddUniqueIndexToSharedMainAccountUsers < ActiveRecord::Migration[7.0]
  def change
    add_index :shared_main_account_users, [:user_id, :main_account_id], unique: true
  end
end
