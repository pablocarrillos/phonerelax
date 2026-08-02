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

ActiveRecord::Schema[8.1].define(version: 2026_08_02_174554) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "contact_messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.text "message"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "order_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event", null: false
    t.bigint "order_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_events_on_order_id"
  end

  create_table "order_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 8, scale: 2
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["product_id"], name: "index_order_lines_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "customer_name", null: false
    t.string "email", null: false
    t.string "locale", default: "es", null: false
    t.string "number", null: false
    t.integer "payment_status", default: 0, null: false
    t.string "phone"
    t.string "postal_code"
    t.string "province"
    t.decimal "shipping_cost", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.string "stripe_session_id"
    t.decimal "total", precision: 8, scale: 2
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_orders_on_number", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.text "body_en"
    t.text "body_pt"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.text "excerpt_en"
    t.text "excerpt_pt"
    t.string "image_url"
    t.date "published_on"
    t.string "slug", null: false
    t.string "title", null: false
    t.string "title_en"
    t.string "title_pt"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_posts_on_slug", unique: true
  end

  create_table "product_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position"
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["product_id"], name: "index_product_images_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "description_en"
    t.text "description_pt"
    t.string "image_url"
    t.string "name", null: false
    t.string "name_en"
    t.string "name_pt"
    t.integer "position", default: 0, null: false
    t.decimal "price", precision: 8, scale: 2, null: false
    t.string "shopify_handle"
    t.integer "stock", default: 0, null: false
    t.datetime "updated_at", null: false
    t.decimal "vat_percentage", precision: 5, scale: 2, default: "21.0", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "order_events", "orders"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "order_lines", "products"
  add_foreign_key "product_images", "products"
  add_foreign_key "sessions", "users"
end
