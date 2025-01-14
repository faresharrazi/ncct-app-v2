class CreateMainTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :main_transactions do |t|
      t.string :title, null: false
      t.text :description
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :transaction_kind, null: false
      t.references :main_account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
