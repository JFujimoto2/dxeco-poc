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

ActiveRecord::Schema[8.1].define(version: 2026_02_10_114352) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "saas_accounts", force: :cascade do |t|
    t.string "account_email"
    t.datetime "created_at", null: false
    t.datetime "last_login_at"
    t.text "notes"
    t.string "role"
    t.bigint "saas_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["saas_id", "user_id"], name: "index_saas_accounts_on_saas_id_and_user_id", unique: true
    t.index ["saas_id"], name: "index_saas_accounts_on_saas_id"
    t.index ["status"], name: "index_saas_accounts_on_status"
    t.index ["user_id"], name: "index_saas_accounts_on_user_id"
  end

  create_table "saas_contracts", force: :cascade do |t|
    t.string "billing_cycle"
    t.datetime "created_at", null: false
    t.date "expires_on"
    t.text "notes"
    t.string "plan_name"
    t.integer "price_cents"
    t.bigint "saas_id", null: false
    t.date "started_on"
    t.datetime "updated_at", null: false
    t.string "vendor"
    t.index ["saas_id"], name: "index_saas_contracts_on_saas_id", unique: true
  end

  create_table "saases", force: :cascade do |t|
    t.string "admin_url"
    t.string "category"
    t.datetime "created_at", null: false
    t.jsonb "custom_fields", default: {}
    t.text "description"
    t.string "name", null: false
    t.bigint "owner_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["category"], name: "index_saases_on_category"
    t.index ["name"], name: "index_saases_on_name"
    t.index ["owner_id"], name: "index_saases_on_owner_id"
    t.index ["status"], name: "index_saases_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "account_enabled", default: true
    t.datetime "created_at", null: false
    t.string "department"
    t.string "display_name"
    t.string "email", null: false
    t.string "employee_id"
    t.string "entra_id_sub", null: false
    t.string "job_title"
    t.datetime "last_signed_in_at"
    t.string "role", default: "viewer", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["entra_id_sub"], name: "index_users_on_entra_id_sub", unique: true
  end

  add_foreign_key "saas_accounts", "saases", column: "saas_id"
  add_foreign_key "saas_accounts", "users"
  add_foreign_key "saas_contracts", "saases", column: "saas_id"
  add_foreign_key "saases", "users", column: "owner_id"
end
