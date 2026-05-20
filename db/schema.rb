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

ActiveRecord::Schema[8.1].define(version: 2026_05_20_120000) do
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

  create_table "bill_participants", force: :cascade do |t|
    t.string "avatar_background_color"
    t.string "avatar_text_color"
    t.bigint "bill_id", null: false
    t.datetime "created_at", null: false
    t.string "initials"
    t.boolean "is_host", default: false, null: false
    t.string "name", null: false
    t.integer "seat_index"
    t.boolean "settled", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id", "seat_index"], name: "index_bill_participants_on_bill_id_and_seat_index"
    t.index ["bill_id"], name: "index_bill_participants_on_bill_id"
  end

  create_table "bills", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "status", default: "draft", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["status"], name: "index_bills_on_status"
    t.index ["user_id"], name: "index_bills_on_user_id"
  end

  create_table "item_assignments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.bigint "bill_participant_id", null: false
    t.datetime "created_at", null: false
    t.bigint "receipt_item_id", null: false
    t.string "split_method", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_participant_id"], name: "index_item_assignments_on_bill_participant_id"
    t.index ["receipt_item_id", "bill_participant_id"], name: "index_item_assignments_on_receipt_item_and_participant", unique: true
    t.index ["receipt_item_id"], name: "index_item_assignments_on_receipt_item_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notifications_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "notification_id", null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notification_id"], name: "index_notifications_users_on_notification_id"
    t.index ["user_id"], name: "index_notifications_users_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.bigint "resource_owner_id", null: false
    t.datetime "revoked_at"
    t.string "scopes", default: "", null: false
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.integer "expires_in"
    t.string "previous_refresh_token", default: "", null: false
    t.string "refresh_token"
    t.bigint "resource_owner_id"
    t.datetime "revoked_at"
    t.string "scopes"
    t.string "token", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.string "secret", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "receipt_adjustments", force: :cascade do |t|
    t.boolean "affects_total", default: false, null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "label", null: false
    t.integer "position", default: 0, null: false
    t.bigint "receipt_id", null: false
    t.datetime "updated_at", null: false
    t.index ["receipt_id", "kind"], name: "index_receipt_adjustments_on_receipt_id_and_kind"
    t.index ["receipt_id", "position"], name: "index_receipt_adjustments_on_receipt_id_and_position"
    t.index ["receipt_id"], name: "index_receipt_adjustments_on_receipt_id"
  end

  create_table "receipt_images", force: :cascade do |t|
    t.string "capture_type", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "receipt_id", null: false
    t.datetime "updated_at", null: false
    t.index ["receipt_id", "position"], name: "index_receipt_images_on_receipt_id_and_position"
    t.index ["receipt_id"], name: "index_receipt_images_on_receipt_id"
  end

  create_table "receipt_items", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.string "category"
    t.decimal "confidence", precision: 5, scale: 4
    t.datetime "created_at", null: false
    t.string "icon_key"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.decimal "quantity", precision: 10, scale: 3, default: "1.0", null: false
    t.bigint "receipt_id"
    t.integer "total_cents", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id", "position"], name: "index_receipt_items_on_bill_id_and_position"
    t.index ["bill_id"], name: "index_receipt_items_on_bill_id"
    t.index ["receipt_id"], name: "index_receipt_items_on_receipt_id"
  end

  create_table "receipt_processing_runs", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "provider"
    t.jsonb "raw_ai_response"
    t.text "raw_ocr_text"
    t.bigint "receipt_id", null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["receipt_id", "status"], name: "index_receipt_processing_runs_on_receipt_id_and_status"
    t.index ["receipt_id"], name: "index_receipt_processing_runs_on_receipt_id"
    t.index ["status"], name: "index_receipt_processing_runs_on_status"
  end

  create_table "receipts", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "ZAR", null: false
    t.integer "discount_cents", default: 0, null: false
    t.string "merchant_name"
    t.date "receipt_date"
    t.integer "service_fee_cents", default: 0, null: false
    t.string "status", default: "draft", null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "tax_cents", default: 0, null: false
    t.integer "tip_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_receipts_on_bill_id", unique: true
    t.index ["status"], name: "index_receipts_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.integer "failed_otp_attempts", default: 0, null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "last_otp_at"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.string "mobile_number"
    t.string "otp_secret_key", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.datetime "verify_otp_sent_at"
    t.string "verify_otp_token"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bill_participants", "bills"
  add_foreign_key "bills", "users"
  add_foreign_key "item_assignments", "bill_participants"
  add_foreign_key "item_assignments", "receipt_items"
  add_foreign_key "notifications_users", "notifications"
  add_foreign_key "notifications_users", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "receipt_adjustments", "receipts"
  add_foreign_key "receipt_images", "receipts"
  add_foreign_key "receipt_items", "bills"
  add_foreign_key "receipt_items", "receipts"
  add_foreign_key "receipt_processing_runs", "receipts"
  add_foreign_key "receipts", "bills"
end
