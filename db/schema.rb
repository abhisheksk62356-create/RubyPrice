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

ActiveRecord::Schema[8.1].define(version: 2026_09_01_000008) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "crawl_runs", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "error_code"
    t.text "error_message"
    t.integer "http_status"
    t.bigint "product_id"
    t.integer "response_time_ms"
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["created_at"], name: "index_crawl_runs_on_created_at"
    t.index ["product_id"], name: "index_crawl_runs_on_product_id"
    t.index ["status"], name: "index_crawl_runs_on_status"
  end

  create_table "price_alerts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.string "status", default: "pending", null: false
    t.decimal "target_price", precision: 12, scale: 2, null: false
    t.datetime "triggered_at"
    t.decimal "triggered_price", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_price_alerts_on_product_id"
    t.index ["status"], name: "index_price_alerts_on_status"
    t.index ["user_id"], name: "index_price_alerts_on_user_id"
  end

  create_table "price_histories", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.string "currency", default: "EUR", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.bigint "product_id", null: false
    t.index ["product_id", "checked_at"], name: "index_price_histories_on_product_id_and_checked_at"
    t.index ["product_id"], name: "index_price_histories_on_product_id"
  end

  create_table "product_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_product_groups_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "availability", default: "unknown", null: false
    t.string "canonical_url", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.decimal "current_price", precision: 12, scale: 2
    t.string "domain", null: false
    t.string "image_url"
    t.datetime "last_checked_at"
    t.boolean "monitoring_enabled", default: true, null: false
    t.string "name", null: false
    t.decimal "previous_price", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["canonical_url"], name: "index_products_on_canonical_url", unique: true
    t.index ["domain"], name: "index_products_on_domain"
    t.index ["monitoring_enabled"], name: "index_products_on_monitoring_enabled"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tracked_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label"
    t.boolean "monitoring_enabled", default: true, null: false
    t.bigint "product_group_id"
    t.bigint "product_id", null: false
    t.decimal "target_price", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_group_id"], name: "index_tracked_products_on_product_group_id"
    t.index ["product_id"], name: "index_tracked_products_on_product_id"
    t.index ["user_id", "product_id"], name: "index_tracked_products_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_tracked_products_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.integer "failed_login_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.string "password_digest", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "crawl_runs", "products"
  add_foreign_key "price_alerts", "products"
  add_foreign_key "price_alerts", "users"
  add_foreign_key "price_histories", "products"
  add_foreign_key "product_groups", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tracked_products", "product_groups"
  add_foreign_key "tracked_products", "products"
  add_foreign_key "tracked_products", "users"
end
