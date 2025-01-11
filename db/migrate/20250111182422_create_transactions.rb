class CreateTransactions < ActiveRecord::Migration[7.0] # or 8.0
  def change
    create_table :transactions do |t|
      t.references :sub_account, null: false, foreign_key: true
      t.references :category, foreign_key: true
      # We'll manually set to_table for :creator if you want it to reference :users
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.string  :title
      t.text    :description
      t.decimal :amount, precision: 15, scale: 2, null: false, default: 0

      # 0 => expense, 1 => income
      t.integer :transaction_type, default: 0

      # Recurrent transactions
      t.integer :frequency, default: 0
      t.string  :frequency_unit, default: "days"

      t.timestamps
    end
  end
end
