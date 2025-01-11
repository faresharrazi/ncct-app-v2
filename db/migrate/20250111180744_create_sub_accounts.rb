class CreateSubAccounts < ActiveRecord::Migration[7.0]  # or 8.0, depending on your Rails version
  def change
    create_table :sub_accounts do |t|
      t.references :main_account, null: false, foreign_key: true
      t.string :title
      t.string :description

      # Provide defaults and specify precision/scale
      t.decimal :balance, default: 0, precision: 15, scale: 2
      t.decimal :percentage, default: 0, precision: 5, scale: 2

      t.timestamps
    end
  end
end
