class CreateMainAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :main_accounts do |t|
      # Make sure it references :users, not a non-existent :owners table
      t.references :owner, null: false, foreign_key: { to_table: :users }

      # Use default values and precision/scale for decimals
      t.string  :title,                 default: "Main Account"
      t.decimal :balance,               default: 0, precision: 15, scale: 2
      t.decimal :available_percentage,  default: 100, precision: 5, scale: 2
      t.string  :currency,              default: "EUR"

      t.timestamps
    end
  end
end
