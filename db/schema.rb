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

ActiveRecord::Schema.define(version: 20180613083447) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "brands", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fulfillments", force: :cascade do |t|
    t.bigint "pick_ticket"
    t.string "status"
    t.bigint "brand_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_fulfillments_on_brand_id"
  end

  create_table "inventory_logs", force: :cascade do |t|
    t.string "sku"
    t.string "name"
    t.bigint "brand_id"
    t.bigint "shopify_variant"
    t.bigint "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_inventory_logs_on_brand_id"
  end

  create_table "inventory_on_hands", force: :cascade do |t|
    t.string "sku"
    t.bigint "brand_id"
    t.float "threshold_percentage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.index ["brand_id"], name: "index_inventory_on_hands_on_brand_id"
  end

  create_table "inventory_trails", force: :cascade do |t|
    t.bigint "inventory_id"
    t.integer "cims_quantity"
    t.integer "shopify_quantity"
    t.integer "flow"
    t.integer "adjustment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_id"], name: "index_inventory_trails_on_inventory_id"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "name"
    t.datetime "runned_at"
    t.bigint "brand_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "xml_request"
    t.string "xml_result"
    t.index ["brand_id"], name: "index_jobs_on_brand_id"
  end

  create_table "log_trails", force: :cascade do |t|
    t.string "logtrailable_type"
    t.bigint "logtrailable_id"
    t.integer "action_type"
    t.integer "recurring_tries"
    t.integer "status"
    t.text "headline"
    t.bigint "brand_id"
    t.integer "trigger_type"
    t.text "log_file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.index ["brand_id"], name: "index_log_trails_on_brand_id"
    t.index ["logtrailable_type", "logtrailable_id"], name: "index_log_trails_on_logtrailable_type_and_logtrailable_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "name"
    t.text "order_detail"
    t.string "source"
    t.bigint "brand_id"
    t.string "tracking_id"
    t.integer "status"
    t.decimal "price"
    t.string "customer_name"
    t.jsonb "details", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "xml_request"
    t.string "xml_result"
    t.index ["brand_id"], name: "index_orders_on_brand_id"
    t.index ["details"], name: "index_orders_on_details", using: :gin
  end

  create_table "products", force: :cascade do |t|
    t.date "product_date"
    t.boolean "default"
    t.string "sku"
    t.bigint "brand_id"
    t.string "product_title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_id"
    t.index ["brand_id"], name: "index_products_on_brand_id"
  end

  create_table "reserve_inventories", force: :cascade do |t|
    t.bigint "brand_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "variant_sku"
    t.string "product_type"
    t.string "size"
    t.integer "size_count"
    t.string "collection_name"
    t.bigint "inventory_item_id"
    t.bigint "collection_id"
    t.bigint "product_id"
    t.integer "delivered_count", default: 0
    t.index ["brand_id"], name: "index_reserve_inventories_on_brand_id"
  end

  create_table "user_brands", force: :cascade do |t|
    t.bigint "brand_id"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_user_brands_on_brand_id"
    t.index ["user_id"], name: "index_user_brands_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.boolean "is_admin", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "name"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "fulfillments", "brands"
  add_foreign_key "inventory_logs", "brands"
  add_foreign_key "inventory_on_hands", "brands"
  add_foreign_key "inventory_trails", "reserve_inventories", column: "inventory_id"
  add_foreign_key "jobs", "brands"
  add_foreign_key "log_trails", "brands"
  add_foreign_key "orders", "brands"
  add_foreign_key "products", "brands"
  add_foreign_key "reserve_inventories", "brands"
  add_foreign_key "user_brands", "brands"
  add_foreign_key "user_brands", "users"
end
