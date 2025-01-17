class AddStatusToSharedMainAccountUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :shared_main_account_users, :status, :string, default: 'pending'
  end
end
