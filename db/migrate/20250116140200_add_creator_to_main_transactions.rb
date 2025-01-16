class AddCreatorToMainTransactions < ActiveRecord::Migration[8.0]
  def change
        add_reference :main_transactions, :creator, null: false, foreign_key: { to_table: :users }
  end
end
