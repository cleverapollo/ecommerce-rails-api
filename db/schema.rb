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

ActiveRecord::Schema.define(version: 20151207083621) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

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
  add_index "actions", ["shop_id", "item_id", "timestamp"], name: "popular_index_by_purchases", where: "(purchase_count > 0)", using: :btree
  add_index "actions", ["shop_id", "item_id", "timestamp"], name: "popular_index_by_rating", using: :btree
  add_index "actions", ["shop_id", "timestamp"], name: "buying_now_index", using: :btree
  add_index "actions", ["shop_id"], name: "index_actions_on_shop_id", using: :btree
  add_index "actions", ["user_id", "item_id"], name: "index_actions_on_user_id_and_item_id", unique: true, using: :btree
  add_index "actions", ["user_id"], name: "index_actions_on_user_id", using: :btree

  create_table "articles", force: :cascade do |t|
    t.string   "external_id",              null: false
    t.text     "url"
    t.integer  "medium_id"
    t.string   "title",       limit: 5000
    t.text     "image"
    t.text     "description"
    t.string   "encoding"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "beacon_messages", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",         limit: 8
    t.integer  "session_id",      limit: 8
    t.text     "params",                                      null: false
    t.boolean  "notified",                    default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "deal_id",         limit: 255
    t.boolean  "tracked",                     default: false, null: false
    t.integer  "beacon_offer_id"
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

  add_index "client_errors", ["shop_id"], name: "index_client_errors_on_shop_id", where: "(resolved = false)", using: :btree

  create_table "clients", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                              null: false
    t.integer  "user_id",                   limit: 8,                                  null: false
    t.boolean  "bought_something",                      default: false,                null: false
    t.integer  "ab_testing_group"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "external_id",               limit: 255
    t.string   "email",                     limit: 255
    t.boolean  "digests_enabled",                       default: true,                 null: false
    t.uuid     "code",                                  default: "uuid_generate_v4()"
    t.boolean  "subscription_popup_showed",             default: false,                null: false
    t.boolean  "triggers_enabled",                      default: true,                 null: false
    t.datetime "last_trigger_mail_sent_at"
    t.boolean  "accepted_subscription",                 default: false,                null: false
    t.string   "location"
    t.date     "last_activity_at"
  end

  add_index "clients", ["accepted_subscription", "shop_id"], name: "index_clients_on_accepted_subscription_and_shop_id", where: "(subscription_popup_showed = true)", using: :btree
  add_index "clients", ["code"], name: "index_clients_on_code", unique: true, using: :btree
  add_index "clients", ["digests_enabled", "shop_id"], name: "index_clients_on_digests_enabled_and_shop_id", using: :btree
  add_index "clients", ["email"], name: "index_clients_on_email", using: :btree
  add_index "clients", ["shop_id", "external_id"], name: "index_clients_on_shop_id_and_external_id", where: "(external_id IS NOT NULL)", using: :btree
  add_index "clients", ["shop_id", "id"], name: "shops_users_shop_id_id_idx", where: "((email IS NOT NULL) AND (digests_enabled = true))", using: :btree
  add_index "clients", ["shop_id", "last_activity_at"], name: "index_clients_on_shop_id_and_last_activity_at", where: "(((email IS NOT NULL) AND (triggers_enabled IS TRUE)) AND (last_activity_at IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "last_trigger_mail_sent_at"], name: "idx_clients_shop_id_last_trigger_email_nulls_first", where: "((triggers_enabled = true) AND (email IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "user_id"], name: "index_clients_on_shop_id_and_user_id", using: :btree
  add_index "clients", ["shop_id"], name: "index_clients_on_shop_id", using: :btree
  add_index "clients", ["subscription_popup_showed", "shop_id"], name: "index_clients_on_subscription_popup_showed_and_shop_id", using: :btree
  add_index "clients", ["triggers_enabled", "shop_id"], name: "index_clients_on_triggers_enabled_and_shop_id", using: :btree
  add_index "clients", ["user_id"], name: "index_clients_on_user_id", using: :btree

  create_table "digest_mailing_batches", id: :bigserial, force: :cascade do |t|
    t.integer "digest_mailing_id", limit: 8,                   null: false
    t.integer "end_id",            limit: 8
    t.boolean "completed",                     default: false, null: false
    t.integer "start_id",          limit: 8
    t.string  "test_email",        limit: 255
    t.integer "shop_id"
  end

  add_index "digest_mailing_batches", ["digest_mailing_id"], name: "index_digest_mailing_batches_on_digest_mailing_id", using: :btree
  add_index "digest_mailing_batches", ["shop_id"], name: "index_digest_mailing_batches_on_shop_id", using: :btree

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

  create_table "interactions", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                    null: false
    t.integer  "user_id",          limit: 8, null: false
    t.integer  "item_id",          limit: 8, null: false
    t.integer  "code",                       null: false
    t.integer  "recommender_code"
    t.datetime "created_at",                 null: false
  end

  add_index "interactions", ["shop_id", "created_at", "recommender_code"], name: "interactions_shop_id_created_at_recommender_code_idx", where: "(code = 1)", using: :btree
  add_index "interactions", ["user_id"], name: "index_interactions_on_user_id", using: :btree

  create_table "item_categories", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                      null: false
    t.integer  "parent_id",          limit: 8
    t.string   "external_id",                  null: false
    t.string   "parent_external_id"
    t.string   "name"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "item_categories", ["shop_id", "external_id"], name: "index_item_categories_on_shop_id_and_external_id", unique: true, using: :btree

  create_table "items", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",                                     null: false
    t.string  "uniqid",         limit: 255,                  null: false
    t.decimal "price"
    t.boolean "is_available",                default: true,  null: false
    t.string  "name",           limit: 255
    t.text    "description"
    t.text    "url"
    t.text    "image_url"
    t.boolean "widgetable",                  default: false, null: false
    t.string  "brand",          limit: 255
    t.string  "categories",                  default: [],                 array: true
    t.boolean "ignored",                     default: false, null: false
    t.jsonb   "locations",                   default: {},    null: false
    t.float   "sr"
    t.integer "sales_rate",     limit: 2
    t.string  "type_prefix"
    t.string  "vendor_code"
    t.string  "model"
    t.string  "gender",         limit: 1
    t.string  "wear_type",      limit: 20
    t.string  "feature",        limit: 20
    t.string  "sizes",                       default: [],                 array: true
    t.float   "age_min"
    t.float   "age_max"
    t.boolean "hypoallergenic"
    t.string  "part_type",                                                array: true
    t.string  "skin_type",                                                array: true
    t.string  "condition",                                                array: true
    t.jsonb   "volume"
    t.boolean "periodic"
    t.string  "barcode",        limit: 1914
    t.string  "category_ids",                                             array: true
    t.string  "location_ids",                                             array: true
  end

  add_index "items", ["brand"], name: "index_items_on_brand", where: "(brand IS NOT NULL)", using: :btree
  add_index "items", ["categories"], name: "index_items_on_categories", using: :gin
  add_index "items", ["categories"], name: "index_items_on_categories_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["locations"], name: "index_items_on_locations", using: :gin
  add_index "items", ["locations"], name: "index_items_on_locations_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["price"], name: "index_items_on_price", where: "(((is_available = true) AND (ignored = false)) AND (price IS NOT NULL))", using: :btree
  add_index "items", ["shop_id", "gender"], name: "index_items_on_shop_id_and_gender", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id", "sales_rate"], name: "available_items_with_sales_rate", where: "((((is_available = true) AND (ignored = false)) AND (sales_rate IS NOT NULL)) AND (sales_rate > 0))", using: :btree
  add_index "items", ["shop_id", "uniqid"], name: "index_items_on_shop_id_and_uniqid", unique: true, using: :btree
  add_index "items", ["shop_id"], name: "index_items_on_shop_id", using: :btree
  add_index "items", ["shop_id"], name: "shop_available_index", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id"], name: "widgetable_shop", where: "(((widgetable = true) AND (is_available = true)) AND (ignored = false))", using: :btree
  add_index "items", ["sizes"], name: "index_items_on_sizes_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin

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

  create_table "medium_actions", force: :cascade do |t|
    t.integer  "medium_id"
    t.integer  "user_id"
    t.integer  "article_id"
    t.string   "medium_action_type", null: false
    t.string   "recommended_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "order_items", id: :bigserial, force: :cascade do |t|
    t.integer "order_id",       limit: 8,               null: false
    t.integer "item_id",        limit: 8,               null: false
    t.integer "action_id",      limit: 8,               null: false
    t.integer "amount",                     default: 1, null: false
    t.string  "recommended_by", limit: 255
    t.integer "shop_id"
  end

  add_index "order_items", ["item_id"], name: "index_order_items_on_item_id", using: :btree
  add_index "order_items", ["order_id"], name: "index_order_items_on_order_id", using: :btree
  add_index "order_items", ["shop_id"], name: "index_order_items_on_shop_id", using: :btree

  create_table "orders", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                       null: false
    t.integer  "user_id",           limit: 8,                   null: false
    t.string   "uniqid",            limit: 255,                 null: false
    t.datetime "date",                                          null: false
    t.decimal  "value",                         default: 0.0,   null: false
    t.boolean  "recommended",                   default: false, null: false
    t.integer  "ab_testing_group"
    t.decimal  "recommended_value",             default: 0.0,   null: false
    t.decimal  "common_value",                  default: 0.0,   null: false
    t.integer  "source_id",         limit: 8
    t.string   "source_type"
    t.integer  "status",                        default: 0,     null: false
    t.date     "status_date"
  end

  add_index "orders", ["date"], name: "index_orders_on_date", using: :btree
  add_index "orders", ["shop_id", "date"], name: "index_orders_on_shop_id_and_date", using: :btree
  add_index "orders", ["shop_id", "status", "status_date"], name: "index_orders_on_shop_id_and_status_and_status_date", using: :btree
  add_index "orders", ["shop_id", "uniqid"], name: "index_orders_on_shop_id_and_uniqid", unique: true, using: :btree
  add_index "orders", ["shop_id"], name: "index_orders_on_shop_id", using: :btree
  add_index "orders", ["source_type", "source_id"], name: "index_orders_on_source_type_and_source_id", using: :btree
  add_index "orders", ["uniqid"], name: "index_orders_on_uniqid", using: :btree
  add_index "orders", ["user_id"], name: "index_orders_on_user_id", using: :btree

  create_table "recommendations_requests", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                           null: false
    t.integer  "category_id",                                       null: false
    t.string   "recommender_type",      limit: 255,                 null: false
    t.boolean  "clicked",                           default: false, null: false
    t.integer  "recommendations_count",                             null: false
    t.text     "recommended_ids",                   default: [],    null: false, array: true
    t.decimal  "duration",                                          null: false
    t.integer  "user_id",               limit: 8
    t.string   "session_code",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shop_metrics", force: :cascade do |t|
    t.integer "shop_id"
    t.integer "orders",                 default: 0,   null: false
    t.integer "real_orders",            default: 0,   null: false
    t.decimal "revenue",                default: 0.0, null: false
    t.decimal "real_revenue",           default: 0.0, null: false
    t.integer "visitors",               default: 0,   null: false
    t.integer "products_viewed",        default: 0,   null: false
    t.integer "triggers_enabled_count", default: 0,   null: false
    t.integer "triggers_orders",        default: 0,   null: false
    t.decimal "triggers_revenue",       default: 0.0, null: false
    t.integer "digests_orders",         default: 0,   null: false
    t.decimal "digests_revenue",        default: 0.0, null: false
    t.integer "abandoned_products",     default: 0,   null: false
    t.decimal "abandoned_money",        default: 0.0, null: false
    t.date    "date",                                 null: false
    t.integer "triggers_sent",          default: 0,   null: false
    t.integer "triggers_clicked",       default: 0,   null: false
    t.decimal "triggers_revenue_real",  default: 0.0, null: false
    t.integer "triggers_orders_real",   default: 0,   null: false
    t.integer "digests_sent",           default: 0,   null: false
    t.integer "digests_clicked",        default: 0,   null: false
    t.decimal "digests_revenue_real",   default: 0.0, null: false
    t.integer "digests_orders_real",    default: 0,   null: false
  end

  add_index "shop_metrics", ["shop_id", "date"], name: "index_shop_metrics_on_shop_id_and_date", unique: true, using: :btree

  create_table "subscriptions_settings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                          null: false
    t.boolean  "enabled",                          default: false, null: false
    t.boolean  "overlay",                          default: true,  null: false
    t.text     "header",                                           null: false
    t.text     "text",                                             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "picture_file_name",    limit: 255
    t.string   "picture_content_type", limit: 255
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.text     "css"
  end

  create_table "trigger_mailings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                          null: false
    t.string   "trigger_type",         limit: 255,                 null: false
    t.string   "subject",              limit: 255,                 null: false
    t.text     "template",                                         null: false
    t.text     "item_template",                                    null: false
    t.boolean  "enabled",                          default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "source_item_template"
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
  add_index "trigger_mails", ["shop_id", "trigger_mailing_id"], name: "index_trigger_mails_on_shop_id_and_trigger_mailing_id", where: "(opened = false)", using: :btree
  add_index "trigger_mails", ["trigger_mailing_id"], name: "index_trigger_mails_on_trigger_mailing_id", using: :btree

end
