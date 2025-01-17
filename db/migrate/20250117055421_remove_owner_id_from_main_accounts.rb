class RemoveOwnerIdFromMainAccounts < ActiveRecord::Migration[8.0]
  def change
    remove_column :main_accounts, :owner_id, :integer
  end
end
