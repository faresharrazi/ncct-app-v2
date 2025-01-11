class AddDefaultCategoryIdToSubAccounts < ActiveRecord::Migration[7.0]
  def change
    add_reference :sub_accounts, :default_category, foreign_key: { to_table: :categories }
  end
end
