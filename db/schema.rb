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

ActiveRecord::Schema[8.1].define(version: 2026_08_04_162004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.string "tax_id"
    t.datetime "updated_at", null: false
  end

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
    t.text "admin_notes"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "customer_name", null: false
    t.string "email", null: false
    t.string "locale", default: "es", null: false
    t.string "number", null: false
    t.boolean "paid_manually", default: false, null: false
    t.integer "payment_status", default: 0, null: false
    t.string "phone"
    t.string "postal_code"
    t.string "province"
    t.decimal "refunded_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "shipping_cost", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_session_id"
    t.decimal "total", precision: 8, scale: 2
    t.string "tracking_carrier"
    t.string "tracking_number"
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
    t.string "slug_en"
    t.string "slug_pt"
    t.string "title", null: false
    t.string "title_en"
    t.string "title_pt"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_posts_on_slug", unique: true
    t.index ["slug_en"], name: "index_posts_on_slug_en", unique: true
    t.index ["slug_pt"], name: "index_posts_on_slug_pt", unique: true
  end

  create_table "price_tiers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "min_units", null: false
    t.bigint "product_id", null: false
    t.decimal "unit_price", precision: 10, scale: 4, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "min_units"], name: "index_price_tiers_on_product_id_and_min_units", unique: true
    t.index ["product_id"], name: "index_price_tiers_on_product_id"
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
    t.decimal "shipping_unit_cost", precision: 8, scale: 2, default: "1.0", null: false
    t.string "shopify_handle"
    t.integer "stock", default: 0, null: false
    t.datetime "updated_at", null: false
    t.decimal "vat_percentage", precision: 5, scale: 2, default: "21.0", null: false
  end

  create_table "purchase_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_cost", precision: 10, scale: 4, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_lines_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_lines_on_purchase_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "customs_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.date "ordered_on", null: false
    t.decimal "other_costs", precision: 10, scale: 2, default: "0.0", null: false
    t.date "received_on"
    t.string "reference"
    t.decimal "shipping_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
  end

  create_table "quote_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.bigint "product_id"
    t.integer "quantity", null: false
    t.bigint "quote_id", null: false
    t.decimal "unit_price", precision: 10, scale: 4, null: false
    t.datetime "updated_at", null: false
    t.decimal "vat_rate", precision: 5, scale: 2, default: "21.0", null: false
    t.index ["product_id"], name: "index_quote_lines_on_product_id"
    t.index ["quote_id"], name: "index_quote_lines_on_quote_id"
  end

  create_table "quote_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.text "message"
    t.string "name"
    t.string "organization"
    t.string "phone"
    t.string "sector"
    t.integer "units"
    t.datetime "updated_at", null: false
  end

  create_table "quotes", force: :cascade do |t|
    t.string "bank_account"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.string "delivery_terms"
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.date "issued_on", null: false
    t.text "notes"
    t.string "number", null: false
    t.string "payment_terms"
    t.text "remarks"
    t.decimal "shipping_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.string "shipping_country", default: "España (Península)", null: false
    t.datetime "updated_at", null: false
    t.date "valid_until"
    t.decimal "vat_rate", precision: 5, scale: 2, default: "21.0", null: false
    t.index ["client_id"], name: "index_quotes_on_client_id"
    t.index ["number"], name: "index_quotes_on_number", unique: true
  end

  create_table "sample_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.bigint "sample_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sample_lines_on_product_id"
    t.index ["sample_id"], name: "index_sample_lines_on_sample_id"
  end

  create_table "samples", force: :cascade do |t|
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.string "email"
    t.text "notes"
    t.string "organization", null: false
    t.date "returned_on"
    t.date "sent_on"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shipping_rates", force: :cascade do |t|
    t.decimal "base_cost", precision: 8, scale: 2, null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_shipping_rates_on_country", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "address"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.text "notes"
    t.string "phone"
    t.string "tax_id"
    t.datetime "updated_at", null: false
    t.string "website"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "order_events", "orders"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "order_lines", "products"
  add_foreign_key "price_tiers", "products"
  add_foreign_key "product_images", "products"
  add_foreign_key "purchase_lines", "products"
  add_foreign_key "purchase_lines", "purchases"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "quote_lines", "products"
  add_foreign_key "quote_lines", "quotes"
  add_foreign_key "quotes", "clients"
  add_foreign_key "sample_lines", "products"
  add_foreign_key "sample_lines", "samples"
  add_foreign_key "sessions", "users"
end
