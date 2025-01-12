class MakeSubAccountIdNullableInCategories < ActiveRecord::Migration[8.0]
  def change
    change_column_null :categories, :sub_account_id, true
  end
end
