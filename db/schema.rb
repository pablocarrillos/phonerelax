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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_100000) do
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

  create_table "company_settings", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "legal_name", null: false
    t.string "phone"
    t.string "postal_code"
    t.string "province"
    t.integer "quote_next_number", default: 1, null: false
    t.string "quote_series", default: "PRES", null: false
    t.integer "quote_series_year"
    t.string "tax_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "verifactu_enabled", default: false, null: false
    t.string "verifactu_environment", default: "test", null: false
    t.string "verifactu_token"
    t.integer "web_next_number", default: 1, null: false
    t.string "web_series", default: "WEB", null: false
    t.integer "web_series_year"
  end

  create_table "contact_messages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.text "message"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "image_comments", force: :cascade do |t|
    t.string "comment"
    t.datetime "created_at", null: false
    t.string "path", null: false
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_image_comments_on_path", unique: true
  end

  create_table "invoice_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "invoice_id", null: false
    t.integer "position", default: 0, null: false
    t.decimal "quantity", precision: 8, scale: 2, default: "1.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_lines_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.text "client_address"
    t.string "client_email"
    t.string "client_name", null: false
    t.string "client_tax_id"
    t.datetime "created_at", null: false
    t.datetime "emailed_at"
    t.date "issued_on", null: false
    t.string "kind", null: false
    t.string "number", null: false
    t.bigint "order_id"
    t.bigint "quote_id"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.decimal "vat_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.json "vat_lines", default: [], null: false
    t.integer "verifactu_attempts", default: 0, null: false
    t.text "verifactu_error"
    t.string "verifactu_huella"
    t.text "verifactu_qr"
    t.datetime "verifactu_sent_at"
    t.string "verifactu_status", default: "disabled", null: false
    t.string "verifactu_url"
    t.index ["number"], name: "index_invoices_on_number", unique: true
    t.index ["order_id"], name: "index_invoices_on_order_id", unique: true
    t.index ["quote_id"], name: "index_invoices_on_quote_id", unique: true
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
    t.boolean "needs_invoice", default: false, null: false
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
    t.string "tax_address"
    t.string "tax_city"
    t.string "tax_country"
    t.string "tax_id"
    t.string "tax_name"
    t.string "tax_postal_code"
    t.string "tax_province"
    t.decimal "total", precision: 8, scale: 2
    t.string "tracking_carrier"
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.boolean "vat_exempt", default: false, null: false
    t.string "vat_exempt_reason"
    t.boolean "vies_valid"
    t.index ["number"], name: "index_orders_on_number", unique: true
  end

  create_table "pack_items", force: :cascade do |t|
    t.bigint "component_id", null: false
    t.datetime "created_at", null: false
    t.bigint "pack_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["component_id"], name: "index_pack_items_on_component_id"
    t.index ["pack_id"], name: "index_pack_items_on_pack_id"
  end

  create_table "photos", force: :cascade do |t|
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.text "body_de"
    t.text "body_en"
    t.text "body_fr"
    t.text "body_pt"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.text "excerpt_de"
    t.text "excerpt_en"
    t.text "excerpt_fr"
    t.text "excerpt_pt"
    t.string "image_url"
    t.date "published_on"
    t.string "slug", null: false
    t.string "slug_de"
    t.string "slug_en"
    t.string "slug_fr"
    t.string "slug_pt"
    t.string "title", null: false
    t.string "title_de"
    t.string "title_en"
    t.string "title_fr"
    t.string "title_pt"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_posts_on_slug", unique: true
    t.index ["slug_de"], name: "index_posts_on_slug_de", unique: true
    t.index ["slug_en"], name: "index_posts_on_slug_en", unique: true
    t.index ["slug_fr"], name: "index_posts_on_slug_fr", unique: true
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
    t.boolean "auto_carousel", default: false, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "description_de"
    t.text "description_en"
    t.text "description_fr"
    t.text "description_pt"
    t.string "image_url"
    t.string "name", null: false
    t.string "name_de"
    t.string "name_en"
    t.string "name_fr"
    t.string "name_pt"
    t.boolean "pack", default: false, null: false
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
    t.decimal "customs_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.string "description"
    t.decimal "other_costs", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "product_id"
    t.bigint "purchase_id", null: false
    t.integer "quantity", null: false
    t.bigint "quote_id"
    t.decimal "shipping_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "unit_cost", precision: 10, scale: 4, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_lines_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_lines_on_purchase_id"
    t.index ["quote_id"], name: "index_purchase_lines_on_quote_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR", null: false
    t.decimal "exchange_rate", precision: 12, scale: 6
    t.date "expected_on"
    t.date "invoice_date"
    t.text "notes"
    t.date "ordered_on", null: false
    t.date "received_on"
    t.string "reference"
    t.bigint "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.index ["supplier_id"], name: "index_purchases_on_supplier_id"
  end

  create_table "quote_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.integer "position"
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
    t.string "internal_description"
    t.date "issued_on", null: false
    t.boolean "manual_shipping", default: false, null: false
    t.text "notes"
    t.string "number", null: false
    t.integer "payment_status", default: 0, null: false
    t.string "payment_terms"
    t.text "remarks"
    t.decimal "shipping_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.string "shipping_country", default: "España (Península)", null: false
    t.integer "status", default: 0, null: false
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
    t.bigint "quote_id"
    t.date "returned_on"
    t.date "sent_on"
    t.boolean "sold", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["quote_id"], name: "index_samples_on_quote_id"
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
  add_foreign_key "invoice_lines", "invoices"
  add_foreign_key "invoices", "orders"
  add_foreign_key "invoices", "quotes"
  add_foreign_key "order_events", "orders"
  add_foreign_key "order_lines", "orders"
  add_foreign_key "order_lines", "products"
  add_foreign_key "pack_items", "products", column: "component_id"
  add_foreign_key "pack_items", "products", column: "pack_id"
  add_foreign_key "price_tiers", "products"
  add_foreign_key "product_images", "products"
  add_foreign_key "purchase_lines", "products"
  add_foreign_key "purchase_lines", "purchases"
  add_foreign_key "purchase_lines", "quotes"
  add_foreign_key "purchases", "suppliers"
  add_foreign_key "quote_lines", "products"
  add_foreign_key "quote_lines", "quotes"
  add_foreign_key "quotes", "clients"
  add_foreign_key "sample_lines", "products"
  add_foreign_key "sample_lines", "samples"
  add_foreign_key "samples", "quotes"
  add_foreign_key "sessions", "users"
end
