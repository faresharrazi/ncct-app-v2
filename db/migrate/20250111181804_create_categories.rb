class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.references :sub_account, null: false, foreign_key: true
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
