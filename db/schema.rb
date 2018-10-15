# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_10_15_070246) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "affiliations", force: :cascade do |t|
    t.integer "iid", null: false
    t.string "organization", null: false
    t.string "department"
    t.string "email", null: false
    t.string "phone"
    t.string "webpage", null: false
    t.string "token"
    t.string "status", default: "created", null: false
    t.string "supervisor"
    t.string "supervisor_profile"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["iid"], name: "index_affiliations_on_iid"
    t.index ["token"], name: "index_affiliations_on_token"
    t.index ["user_id"], name: "index_affiliations_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.string "ancestry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "services_count", default: 0
    t.index ["ancestry"], name: "index_categories_on_ancestry"
    t.index ["description"], name: "index_categories_on_description"
    t.index ["name"], name: "index_categories_on_name"
  end

  create_table "order_changes", force: :cascade do |t|
    t.string "status"
    t.text "message"
    t.bigint "order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "author_id"
    t.integer "iid"
    t.index ["author_id"], name: "index_order_changes_on_author_id"
    t.index ["order_id"], name: "index_order_changes_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "status", null: false
    t.bigint "service_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "issue_id"
    t.integer "issue_status", default: 2, null: false
    t.index ["service_id"], name: "index_orders_on_service_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "providers", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "service_categories", force: :cascade do |t|
    t.bigint "service_id"
    t.bigint "category_id"
    t.boolean "main", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_service_categories_on_category_id"
    t.index ["service_id"], name: "index_service_categories_on_service_id"
  end

  create_table "service_opinions", force: :cascade do |t|
    t.integer "rating", null: false
    t.text "opinion"
    t.bigint "order_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_service_opinions_on_order_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "terms_of_use"
    t.text "tagline", null: false
    t.bigint "owner_id"
    t.decimal "rating", precision: 2, scale: 1, default: "0.0", null: false
    t.text "connected_url"
    t.boolean "open_access", default: false
    t.bigint "provider_id"
    t.integer "service_opinion_count", default: 0
    t.index ["description"], name: "index_services_on_description"
    t.index ["owner_id"], name: "index_services_on_owner_id"
    t.index ["provider_id"], name: "index_services_on_provider_id"
    t.index ["title"], name: "index_services_on_title"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uid", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "roles_mask"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "order_changes", "users", column: "author_id"
  add_foreign_key "services", "providers"
  add_foreign_key "services", "users", column: "owner_id"
end
