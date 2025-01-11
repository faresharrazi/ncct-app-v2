class CreateSharedMainAccountUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :shared_main_account_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :main_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
