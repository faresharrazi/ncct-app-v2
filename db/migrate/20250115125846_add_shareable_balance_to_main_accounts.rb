class AddShareableBalanceToMainAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :main_accounts, :shareable_balance, :decimal, default: 0.0, precision: 15, scale: 2
  end
end
