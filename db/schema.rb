# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_01_17_091301) do
  create_table "categories", force: :cascade do |t|
    t.integer "sub_account_id"
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sub_account_id"], name: "index_categories_on_sub_account_id"
  end

  create_table "main_accounts", force: :cascade do |t|
    t.string "title", default: "Main Account"
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.decimal "available_percentage", precision: 5, scale: 2, default: "100.0"
    t.string "currency", default: "EUR"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "shareable_balance", precision: 15, scale: 2, default: "0.0"
  end

  create_table "main_accounts_users", id: false, force: :cascade do |t|
    t.integer "main_account_id", null: false
    t.integer "user_id", null: false
    t.index ["main_account_id"], name: "index_main_accounts_users_on_main_account_id"
    t.index ["user_id"], name: "index_main_accounts_users_on_user_id"
  end

  create_table "main_transactions", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "transaction_kind", null: false
    t.integer "main_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "creator_id", null: false
    t.index ["creator_id"], name: "index_main_transactions_on_creator_id"
    t.index ["main_account_id"], name: "index_main_transactions_on_main_account_id"
  end

  create_table "shared_main_account_users", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "main_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pending"
    t.index ["main_account_id"], name: "index_shared_main_account_users_on_main_account_id"
    t.index ["user_id", "main_account_id"], name: "index_shared_main_account_users_on_user_id_and_main_account_id", unique: true
    t.index ["user_id"], name: "index_shared_main_account_users_on_user_id"
  end

  create_table "sub_account_transactions", force: :cascade do |t|
    t.integer "sub_account_id"
    t.integer "category_id"
    t.integer "creator_id", null: false
    t.string "title"
    t.text "description"
    t.decimal "amount", precision: 15, scale: 2, default: "0.0", null: false
    t.string "transaction_kind"
    t.integer "frequency", default: 0
    t.string "frequency_unit", default: "days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "main_account_id"
    t.index ["category_id"], name: "index_sub_account_transactions_on_category_id"
    t.index ["creator_id"], name: "index_sub_account_transactions_on_creator_id"
    t.index ["main_account_id"], name: "index_sub_account_transactions_on_main_account_id"
    t.index ["sub_account_id"], name: "index_sub_account_transactions_on_sub_account_id"
  end

  create_table "sub_accounts", force: :cascade do |t|
    t.integer "main_account_id", null: false
    t.string "title"
    t.string "description"
    t.decimal "balance", precision: 15, scale: 2, default: "0.0"
    t.decimal "percentage", precision: 5, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "default_category_id"
    t.index ["default_category_id"], name: "index_sub_accounts_on_default_category_id"
    t.index ["main_account_id"], name: "index_sub_accounts_on_main_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "main_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["main_account_id"], name: "index_users_on_main_account_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "categories", "sub_accounts"
  add_foreign_key "main_transactions", "main_accounts"
  add_foreign_key "main_transactions", "users", column: "creator_id"
  add_foreign_key "shared_main_account_users", "main_accounts"
  add_foreign_key "shared_main_account_users", "users"
  add_foreign_key "sub_account_transactions", "categories"
  add_foreign_key "sub_account_transactions", "main_accounts"
  add_foreign_key "sub_account_transactions", "sub_accounts"
  add_foreign_key "sub_account_transactions", "users", column: "creator_id"
  add_foreign_key "sub_accounts", "categories", column: "default_category_id"
  add_foreign_key "sub_accounts", "main_accounts"
end
