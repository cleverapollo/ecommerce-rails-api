# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150709151743) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "uuid-ossp"
  enable_extension "dblink"

  create_table "actions", id: :bigserial, force: :cascade do |t|
    t.integer  "user_id",          limit: 8,                   null: false
    t.integer  "item_id",          limit: 8,                   null: false
    t.integer  "view_count",                   default: 0,     null: false
    t.datetime "view_date"
    t.integer  "cart_count",                   default: 0,     null: false
    t.datetime "cart_date"
    t.integer  "purchase_count",               default: 0,     null: false
    t.datetime "purchase_date"
    t.float    "rating",                       default: 0.0
    t.integer  "shop_id",                                      null: false
    t.integer  "timestamp",                    default: 0,     null: false
    t.string   "recommended_by",   limit: 255
    t.integer  "last_action",      limit: 2,   default: 1,     null: false
    t.integer  "rate_count",                   default: 0,     null: false
    t.datetime "rate_date"
    t.integer  "last_user_rating"
    t.boolean  "repeatable",                   default: false, null: false
    t.datetime "recommended_at"
  end

  add_index "actions", ["item_id"], name: "index_actions_on_item_id", using: :btree
  add_index "actions", ["shop_id", "timestamp"], name: "buying_now_index", using: :btree
  add_index "actions", ["shop_id"], name: "index_actions_on_shop_id", using: :btree
  add_index "actions", ["user_id", "item_id"], name: "index_actions_on_user_id_and_item_id", unique: true, using: :btree
  add_index "actions", ["user_id"], name: "index_actions_on_user_id", using: :btree

  create_table "beacon_messages", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",    limit: 8
    t.integer  "session_id", limit: 8
    t.text     "params",                                 null: false
    t.boolean  "notified",               default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "deal_id",    limit: 255
    t.boolean  "tracked",                default: false, null: false
  end

  create_table "client_errors", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "exception_class",   limit: 255,                 null: false
    t.string   "exception_message", limit: 255,                 null: false
    t.text     "params",                                        null: false
    t.boolean  "resolved",                      default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "referer",           limit: 255
  end

  create_table "digest_mailing_batches", id: :bigserial, force: :cascade do |t|
    t.integer "digest_mailing_id", limit: 8,                   null: false
    t.integer "end_id",            limit: 8
    t.boolean "completed",                     default: false, null: false
    t.integer "start_id",          limit: 8
    t.string  "test_email",        limit: 255
  end

  add_index "digest_mailing_batches", ["digest_mailing_id"], name: "index_digest_mailing_batches_on_digest_mailing_id", using: :btree

  create_table "digest_mailing_settings", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",                             null: false
    t.boolean "on",                  default: false, null: false
    t.string  "sender",  limit: 255,                 null: false
  end

  add_index "digest_mailing_settings", ["shop_id"], name: "index_digest_mailing_settings_on_shop_id", using: :btree

  create_table "digest_mailings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                          null: false
    t.string   "name",              limit: 255,                    null: false
    t.string   "subject",           limit: 255,                    null: false
    t.text     "template",                                         null: false
    t.string   "items",             limit: 255
    t.string   "state",             limit: 255, default: "draft",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "item_template",                                    null: false
    t.integer  "total_mails_count"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text     "header"
    t.text     "text"
    t.string   "edit_mode",         limit: 255, default: "simple", null: false
  end

  add_index "digest_mailings", ["shop_id"], name: "index_digest_mailings_on_shop_id", using: :btree

  create_table "digest_mails", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                          null: false
    t.integer  "digest_mailing_id",       limit: 8,                                null: false
    t.integer  "digest_mailing_batch_id", limit: 8,                                null: false
    t.uuid     "code",                              default: "uuid_generate_v4()"
    t.boolean  "clicked",                           default: false,                null: false
    t.boolean  "opened",                            default: false,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id",               limit: 8,                                null: false
    t.boolean  "bounced",                           default: false,                null: false
  end

  add_index "digest_mails", ["client_id"], name: "index_digest_mails_on_client_id", using: :btree
  add_index "digest_mails", ["code"], name: "index_digest_mails_on_code", unique: true, using: :btree

  create_table "events", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                     null: false
    t.string   "name",            limit: 255,                 null: false
    t.text     "additional_info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "processed",                   default: false, null: false
  end

  add_index "events", ["created_at"], name: "index_events_on_created_at", using: :btree
  add_index "events", ["name"], name: "index_events_on_name", using: :btree
  add_index "events", ["shop_id"], name: "index_events_on_shop_id", using: :btree

  create_table "items", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",                                       null: false
    t.string  "uniqid",            limit: 255,                 null: false
    t.decimal "price"
    t.boolean "is_available",                  default: true,  null: false
    t.string  "name",              limit: 255
    t.text    "description"
    t.text    "url"
    t.text    "image_url"
    t.string  "tags",                          default: [],                 array: true
    t.boolean "widgetable",                    default: false, null: false
    t.string  "brand",             limit: 255
    t.boolean "repeatable",                    default: false, null: false
    t.date    "available_till"
    t.string  "categories",                    default: [],                 array: true
    t.boolean "ignored",                       default: false, null: false
    t.jsonb   "custom_attributes",             default: {},    null: false
    t.jsonb   "locations",                     default: {},    null: false
    t.float   "sr"
    t.integer "sales_rate",        limit: 2
    t.string  "type_prefix"
    t.string  "vendor_code"
    t.string  "model"
    t.string  "gender",            limit: 1
    t.string  "wear_type",         limit: 20
    t.string  "feature",           limit: 20
    t.string  "sizes",                         default: [],                 array: true
  end

  add_index "items", ["brand"], name: "index_items_on_brand", where: "(brand IS NOT NULL)", using: :btree
  add_index "items", ["custom_attributes"], name: "index_items_on_custom_attributes", using: :gin
  add_index "items", ["locations"], name: "index_items_on_locations", using: :gin
  add_index "items", ["locations"], name: "index_items_on_locations_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["shop_id", "sales_rate"], name: "available_items_with_sales_rate", where: "((((is_available = true) AND (ignored = false)) AND (sales_rate IS NOT NULL)) AND (sales_rate > 0))", using: :btree
  add_index "items", ["shop_id"], name: "index_items_on_shop_id", using: :btree
  add_index "items", ["shop_id"], name: "shop_available_index", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["uniqid", "shop_id"], name: "items_uniqid_shop_id_key", unique: true, using: :btree

  create_table "mailings_settings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                       null: false
    t.string   "send_from",         limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "logo_file_name",    limit: 255
    t.string   "logo_content_type", limit: 255
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
  end

  create_table "trigger_mailings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                   null: false
    t.string   "trigger_type",  limit: 255,                 null: false
    t.string   "subject",       limit: 255,                 null: false
    t.text     "template",                                  null: false
    t.text     "item_template",                             null: false
    t.boolean  "enabled",                   default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "trigger_mailings", ["shop_id", "trigger_type"], name: "index_trigger_mailings_on_shop_id_and_trigger_type", unique: true, using: :btree

  create_table "trigger_mails", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                     null: false
    t.text     "trigger_data",                                                null: false
    t.uuid     "code",                         default: "uuid_generate_v4()"
    t.boolean  "clicked",                      default: false,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "opened",                       default: false,                null: false
    t.integer  "trigger_mailing_id", limit: 8,                                null: false
    t.boolean  "bounced",                      default: false,                null: false
    t.integer  "client_id",          limit: 8,                                null: false
  end

  add_index "trigger_mails", ["code"], name: "index_trigger_mails_on_code", unique: true, using: :btree
  add_index "trigger_mails", ["trigger_mailing_id"], name: "index_trigger_mails_on_trigger_mailing_id", using: :btree

end
