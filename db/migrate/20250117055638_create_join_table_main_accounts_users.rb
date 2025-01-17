class CreateJoinTableMainAccountsUsers < ActiveRecord::Migration[8.0]
  def change
    create_join_table :main_accounts, :users do |t|
      t.index :main_account_id
      t.index :user_id
    end
  end
end
