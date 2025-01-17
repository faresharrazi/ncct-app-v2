class CreateMainAccountsUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :main_accounts_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :main_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
