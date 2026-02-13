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

ActiveRecord::Schema[8.1].define(version: 2026_02_13_032024) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "approval_requests", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.bigint "approver_id"
    t.datetime "created_at", null: false
    t.integer "estimated_cost"
    t.text "reason"
    t.text "rejection_reason"
    t.string "request_type", default: "add_account", null: false
    t.bigint "requester_id", null: false
    t.bigint "saas_id"
    t.string "saas_name"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_count"
    t.index ["approved_by_id"], name: "index_approval_requests_on_approved_by_id"
    t.index ["approver_id"], name: "index_approval_requests_on_approver_id"
    t.index ["requester_id"], name: "index_approval_requests_on_requester_id"
    t.index ["saas_id"], name: "index_approval_requests_on_saas_id"
    t.index ["status"], name: "index_approval_requests_on_status"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.jsonb "changes_data", default: {}
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "resource_id", null: false
    t.string "resource_type", null: false
    t.bigint "user_id"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "batch_execution_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_count", default: 0
    t.integer "error_count", default: 0
    t.text "error_messages"
    t.datetime "finished_at"
    t.string "job_name", null: false
    t.integer "processed_count", default: 0
    t.datetime "started_at"
    t.string "status", default: "running", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_count", default: 0
  end

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

  create_table "survey_responses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "notes"
    t.datetime "responded_at"
    t.string "response"
    t.bigint "saas_account_id"
    t.bigint "survey_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["saas_account_id"], name: "index_survey_responses_on_saas_account_id"
    t.index ["survey_id", "user_id", "saas_account_id"], name: "idx_survey_responses_unique", unique: true
    t.index ["survey_id"], name: "index_survey_responses_on_survey_id"
    t.index ["user_id"], name: "index_survey_responses_on_user_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "deadline"
    t.datetime "sent_at"
    t.string "status", default: "draft", null: false
    t.string "survey_type", default: "account_review", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_surveys_on_created_by_id"
    t.index ["status"], name: "index_surveys_on_status"
  end

  create_table "task_items", force: :cascade do |t|
    t.string "action_type", null: false
    t.bigint "assignee_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.text "notes"
    t.bigint "saas_id"
    t.string "status", default: "pending", null: false
    t.bigint "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_task_items_on_assignee_id"
    t.index ["saas_id"], name: "index_task_items_on_saas_id"
    t.index ["status"], name: "index_task_items_on_status"
    t.index ["task_id"], name: "index_task_items_on_task_id"
  end

  create_table "task_preset_items", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.bigint "default_assignee_id"
    t.string "description", null: false
    t.integer "position", default: 0
    t.bigint "task_preset_id", null: false
    t.datetime "updated_at", null: false
    t.index ["default_assignee_id"], name: "index_task_preset_items_on_default_assignee_id"
    t.index ["task_preset_id"], name: "index_task_preset_items_on_task_preset_id"
  end

  create_table "task_presets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "task_type", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.date "due_date"
    t.string "status", default: "open", null: false
    t.bigint "target_user_id"
    t.string "task_type", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["target_user_id"], name: "index_tasks_on_target_user_id"
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

  add_foreign_key "approval_requests", "saases"
  add_foreign_key "approval_requests", "users", column: "approved_by_id"
  add_foreign_key "approval_requests", "users", column: "approver_id"
  add_foreign_key "approval_requests", "users", column: "requester_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "saas_accounts", "saases"
  add_foreign_key "saas_accounts", "users"
  add_foreign_key "saas_contracts", "saases"
  add_foreign_key "saases", "users", column: "owner_id"
  add_foreign_key "survey_responses", "saas_accounts"
  add_foreign_key "survey_responses", "surveys"
  add_foreign_key "survey_responses", "users"
  add_foreign_key "surveys", "users", column: "created_by_id"
  add_foreign_key "task_items", "saases"
  add_foreign_key "task_items", "tasks"
  add_foreign_key "task_items", "users", column: "assignee_id"
  add_foreign_key "task_preset_items", "task_presets"
  add_foreign_key "task_preset_items", "users", column: "default_assignee_id"
  add_foreign_key "tasks", "users", column: "created_by_id"
  add_foreign_key "tasks", "users", column: "target_user_id"
end
