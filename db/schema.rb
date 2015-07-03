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

ActiveRecord::Schema.define(version: 20150624134829) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "uuid-ossp"

  create_table "actions", force: :cascade do |t|
    t.integer  "user_id",          limit: 8,                   null: false
    t.integer  "item_id",          limit: 8,                   null: false
    t.integer  "view_count",                   default: 0,     null: false
    t.datetime "view_date"
    t.integer  "cart_count",                   default: 0,     null: false
    t.datetime "cart_date"
    t.integer  "purchase_count",               default: 0,     null: false
    t.datetime "purchase_date"
    t.float    "rating",                       default: 0.0
    t.integer  "shop_id",          limit: 8,                   null: false
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

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body"
    t.string   "resource_id",   limit: 255, null: false
    t.string   "resource_type", limit: 255, null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "advertiser_item_categories", force: :cascade do |t|
    t.integer  "advertiser_id"
    t.integer  "item_category_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "advertiser_item_categories", ["advertiser_id"], name: "index_advertiser_item_categories_on_advertiser_id", using: :btree
  add_index "advertiser_item_categories", ["item_category_id"], name: "index_advertiser_item_categories_on_item_category_id", using: :btree

  create_table "advertiser_purchases", force: :cascade do |t|
    t.integer  "advertiser_id"
    t.integer  "item_id"
    t.integer  "shop_id"
    t.integer  "order_id"
    t.float    "price"
    t.string   "recommended_by"
    t.date     "date"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "advertiser_purchases", ["advertiser_id", "shop_id"], name: "index_advertiser_purchases_on_advertiser_id_and_shop_id", using: :btree
  add_index "advertiser_purchases", ["advertiser_id"], name: "index_advertiser_purchases_on_advertiser_id", using: :btree

  create_table "advertiser_shops", force: :cascade do |t|
    t.integer  "advertiser_id"
    t.integer  "shop_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "last_event_at"
  end

  add_index "advertiser_shops", ["advertiser_id"], name: "index_advertiser_shops_on_advertiser_id", using: :btree
  add_index "advertiser_shops", ["shop_id"], name: "index_advertiser_shops_on_shop_id", using: :btree

  create_table "advertiser_statistics", force: :cascade do |t|
    t.integer  "advertiser_id"
    t.integer  "views",                 default: 0,   null: false
    t.integer  "original_purchases",    default: 0,   null: false
    t.integer  "recommended_purchases", default: 0,   null: false
    t.float    "cost",                  default: 0.0, null: false
    t.date     "date",                                null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "recommended_clicks",    default: 0,   null: false
    t.integer  "original_clicks",       default: 0,   null: false
  end

  add_index "advertiser_statistics", ["advertiser_id", "date"], name: "index_advertiser_statistics_on_advertiser_id_and_date", unique: true, using: :btree

  create_table "advertiser_statistics_events", force: :cascade do |t|
    t.integer  "advertiser_statistic_id",                 null: false
    t.integer  "advertiser_shop_id",                      null: false
    t.string   "recommender"
    t.string   "event",                                   null: false
    t.boolean  "recommended",             default: false, null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "advertiser_statistics_events", ["advertiser_statistic_id"], name: "index_advertiser_statistics_events_on_advertiser_statistic_id", using: :btree

  create_table "advertisers", force: :cascade do |t|
    t.string   "email"
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company"
    t.string   "website"
    t.string   "mobile_phone"
    t.string   "work_phone"
    t.string   "country"
    t.string   "city"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "balance",                default: 0.0,   null: false
    t.integer  "cpm",                    default: 1500,  null: false
    t.string   "brand"
    t.string   "downcase_brand"
    t.boolean  "campaign_launched",      default: false, null: false
    t.integer  "priority",               default: 100,   null: false
  end

  add_index "advertisers", ["campaign_launched", "priority"], name: "index_advertisers_on_campaign_launched_and_priority", using: :btree
  add_index "advertisers", ["email"], name: "index_advertisers_on_email", unique: true, using: :btree
  add_index "advertisers", ["reset_password_token"], name: "index_advertisers_on_reset_password_token", unique: true, using: :btree

  create_table "advertisers_orders", force: :cascade do |t|
    t.integer "advertiser_statistics_id"
    t.integer "orders_id"
  end

  add_index "advertisers_orders", ["advertiser_statistics_id"], name: "index_advertisers_orders_on_advertiser_statistics_id", using: :btree

  create_table "audiences", force: :cascade do |t|
    t.integer "shop_id",                                                      null: false
    t.string  "external_id",       limit: 255,                                null: false
    t.integer "user_id"
    t.string  "email",             limit: 255,                                null: false
    t.boolean "active",                        default: true,                 null: false
    t.text    "custom_attributes"
    t.uuid    "code",                          default: "uuid_generate_v4()"
  end

  add_index "audiences", ["code"], name: "index_audiences_on_code", unique: true, using: :btree
  add_index "audiences", ["external_id", "shop_id"], name: "index_audiences_on_external_id_and_shop_id", unique: true, using: :btree
  add_index "audiences", ["user_id"], name: "index_audiences_on_user_id", using: :btree

  create_table "beacon_messages", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id"
    t.integer  "session_id"
    t.text     "params",                                 null: false
    t.boolean  "notified",               default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "deal_id",    limit: 255
    t.boolean  "tracked",                default: false, null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.boolean  "deletable",                   default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code",            limit: 255,                null: false
    t.decimal  "increase_units"
    t.decimal  "increase_rubles"
  end

  add_index "categories", ["code"], name: "index_categories_on_code", unique: true, using: :btree

  create_table "client_errors", force: :cascade do |t|
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

  create_table "client_requests", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.string   "platform"
    t.string   "category"
    t.string   "hosting"
    t.integer  "catalog_size"
    t.integer  "turnover"
    t.text     "comment"
    t.string   "person"
    t.string   "mobile"
    t.string   "email"
    t.string   "skype"
    t.text     "other_contacts"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "clients", force: :cascade do |t|
    t.integer  "shop_id",                                                              null: false
    t.integer  "user_id",                                                              null: false
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
  end

  add_index "clients", ["accepted_subscription", "shop_id"], name: "index_clients_on_accepted_subscription_and_shop_id", where: "(subscription_popup_showed = true)", using: :btree
  add_index "clients", ["code"], name: "index_clients_on_code", unique: true, using: :btree
  add_index "clients", ["digests_enabled", "shop_id"], name: "index_clients_on_digests_enabled_and_shop_id", using: :btree
  add_index "clients", ["email"], name: "index_clients_on_email", using: :btree
  add_index "clients", ["shop_id", "id"], name: "shops_users_shop_id_id_idx", where: "((email IS NOT NULL) AND (digests_enabled = true))", using: :btree

  create_table "cmses", force: :cascade do |t|
    t.string   "code",               limit: 255,                 null: false
    t.string   "name",               limit: 255,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "supported",                      default: false, null: false
    t.string   "documentation_link", limit: 255
  end

  create_table "currencies", force: :cascade do |t|
    t.string   "code",       null: false
    t.string   "symbol",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.integer  "role",                               default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone",                  limit: 255
    t.string   "city",                   limit: 255
    t.string   "company",                limit: 255
    t.boolean  "subscribed",                         default: true,  null: false
    t.string   "unsubscribe_token",      limit: 255
    t.integer  "partner_id"
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.integer  "balance",                            default: 0,     null: false
    t.string   "gift_link",              limit: 255
    t.boolean  "real",                               default: true
    t.boolean  "financial_manager",                  default: false
    t.date     "recent_activity"
    t.string   "promocode"
    t.string   "industry_code"
    t.string   "suggested_plan"
    t.string   "juridical_person"
  end

  add_index "customers", ["email"], name: "index_customers_on_email", unique: true, using: :btree
  add_index "customers", ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true, using: :btree

  create_table "digest_mailing_batches", force: :cascade do |t|
    t.integer "digest_mailing_id",                             null: false
    t.integer "end_id"
    t.boolean "completed",                     default: false, null: false
    t.integer "start_id"
    t.string  "test_email",        limit: 255
  end

  add_index "digest_mailing_batches", ["digest_mailing_id"], name: "index_digest_mailing_batches_on_digest_mailing_id", using: :btree

  create_table "digest_mailing_settings", force: :cascade do |t|
    t.integer "shop_id",                             null: false
    t.boolean "on",                  default: false, null: false
    t.string  "sender",  limit: 255,                 null: false
  end

  add_index "digest_mailing_settings", ["shop_id"], name: "index_digest_mailing_settings_on_shop_id", using: :btree

  create_table "digest_mailings", force: :cascade do |t|
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

  create_table "digest_mails", force: :cascade do |t|
    t.integer  "shop_id",                                                null: false
    t.integer  "digest_mailing_id",                                      null: false
    t.integer  "digest_mailing_batch_id",                                null: false
    t.uuid     "code",                    default: "uuid_generate_v4()"
    t.boolean  "clicked",                 default: false,                null: false
    t.boolean  "opened",                  default: false,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id",                                              null: false
    t.boolean  "bounced",                 default: false,                null: false
  end

  add_index "digest_mails", ["client_id"], name: "index_digest_mails_on_client_id", using: :btree
  add_index "digest_mails", ["code"], name: "index_digest_mails_on_code", unique: true, using: :btree

  create_table "events", force: :cascade do |t|
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

  create_table "faqs", force: :cascade do |t|
    t.text     "question",                null: false
    t.text     "answer",                  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "in_sequence", default: 0, null: false
  end

  create_table "industries", force: :cascade do |t|
    t.string   "code",       null: false
    t.string   "channels",   null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "insales_shops", force: :cascade do |t|
    t.string   "token",        limit: 255
    t.string   "insales_shop", limit: 255
    t.string   "insales_id",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "shop_id"
  end

  add_index "insales_shops", ["shop_id"], name: "index_insales_shops_on_shop_id", using: :btree

  create_table "interactions", force: :cascade do |t|
    t.integer  "shop_id",          null: false
    t.integer  "user_id",          null: false
    t.integer  "item_id",          null: false
    t.integer  "code",             null: false
    t.integer  "recommender_code"
    t.datetime "created_at",       null: false
  end

  add_index "interactions", ["shop_id", "created_at", "recommender_code"], name: "interactions_shop_id_created_at_recommender_code_idx", where: "(code = 1)", using: :btree
  add_index "interactions", ["shop_id", "item_id"], name: "tmpidx_interactions_1", using: :btree
  add_index "interactions", ["user_id"], name: "index_interactions_on_user_id", using: :btree

  create_table "ipn_messages", force: :cascade do |t|
    t.text     "content",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_categories", force: :cascade do |t|
    t.integer  "shop_id",            null: false
    t.integer  "parent_id"
    t.string   "external_id",        null: false
    t.string   "parent_external_id"
    t.string   "name"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "item_categories", ["shop_id", "external_id"], name: "index_item_categories_on_shop_id_and_external_id", unique: true, using: :btree

  create_table "items", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",           limit: 8,                   null: false
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

  create_table "mahout_actions", force: :cascade do |t|
    t.integer "user_id",    limit: 8
    t.integer "item_id",    limit: 8
    t.integer "shop_id",    limit: 8
    t.integer "timestamp"
    t.float   "preference"
  end

  add_index "mahout_actions", ["shop_id"], name: "index_mahout_actions_on_shop_id", using: :btree
  add_index "mahout_actions", ["user_id", "item_id"], name: "index_mahout_actions_on_user_id_and_item_id", unique: true, using: :btree

  create_table "mailings_settings", force: :cascade do |t|
    t.integer  "shop_id",                       null: false
    t.string   "send_from",         limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "logo_file_name",    limit: 255
    t.string   "logo_content_type", limit: 255
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
  end

  create_table "monthly_statistic_items", force: :cascade do |t|
    t.integer  "monthly_statistic_id",                         null: false
    t.string   "type_item",            limit: 255,             null: false
    t.integer  "value",                            default: 1, null: false
    t.integer  "entity_id"
    t.string   "entity_type",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "monthly_statistic_items", ["entity_id", "entity_type"], name: "index_monthly_statistic_items_on_entity_id_and_entity_type", using: :btree
  add_index "monthly_statistic_items", ["monthly_statistic_id"], name: "index_monthly_statistic_items_on_monthly_statistic_id", using: :btree

  create_table "monthly_statistics", force: :cascade do |t|
    t.integer  "month",      limit: 2, null: false
    t.integer  "year",       limit: 2, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "monthly_statistics", ["month", "year"], name: "index_monthly_statistics_on_month_and_year", unique: true, using: :btree

  create_table "order_items", id: :bigserial, force: :cascade do |t|
    t.integer "order_id",       limit: 8,               null: false
    t.integer "item_id",        limit: 8,               null: false
    t.integer "action_id",      limit: 8,               null: false
    t.integer "amount",                     default: 1, null: false
    t.string  "recommended_by", limit: 255
  end

  add_index "order_items", ["item_id"], name: "index_order_items_on_item_id", using: :btree

  create_table "orders", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                       null: false
    t.integer  "user_id",                                                       null: false
    t.string   "uniqid",            limit: 255,                                 null: false
    t.datetime "date",                          default: '2015-06-11 10:16:12', null: false
    t.decimal  "value",                         default: 0.0,                   null: false
    t.boolean  "recommended",                   default: false,                 null: false
    t.integer  "ab_testing_group"
    t.decimal  "recommended_value",             default: 0.0,                   null: false
    t.decimal  "common_value",                  default: 0.0,                   null: false
    t.integer  "source_id"
    t.string   "source_type"
    t.integer  "status",                        default: 0,                     null: false
    t.date     "status_date"
  end

  add_index "orders", ["date"], name: "index_orders_on_date", using: :btree
  add_index "orders", ["shop_id", "status", "status_date"], name: "index_orders_on_shop_id_and_status_and_status_date", using: :btree

  create_table "partner_requests", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.string   "platform_type"
    t.string   "language"
    t.string   "framework"
    t.integer  "clients_base_size"
    t.string   "payment_type"
    t.text     "comment"
    t.string   "person"
    t.string   "mobile"
    t.string   "email"
    t.string   "skype"
    t.text     "other_contacts"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "partners", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "name",                   limit: 255
    t.string   "phone",                  limit: 255
    t.string   "city",                   limit: 255
    t.string   "company",                limit: 255
    t.integer  "role",                               default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token",                  limit: 255,                 null: false
    t.text     "description"
    t.string   "url",                    limit: 255
    t.boolean  "approved",                           default: false, null: false
  end

  add_index "partners", ["email"], name: "index_partners_on_email", unique: true, using: :btree
  add_index "partners", ["reset_password_token"], name: "index_partners_on_reset_password_token", unique: true, using: :btree

  create_table "payments", force: :cascade do |t|
    t.integer  "shop_id",                       null: false
    t.integer  "plan_id",                       null: false
    t.string   "paypal_token",      limit: 255
    t.string   "paypal_payer_id",   limit: 255
    t.string   "paypal_profile_id", limit: 255
    t.string   "state",             limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "plans", force: :cascade do |t|
    t.string   "name",       limit: 255, null: false
    t.integer  "orders_min",             null: false
    t.integer  "orders_max",             null: false
    t.integer  "price"
    t.string   "plan_type",  limit: 255, null: false
    t.text     "mailing"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "potential_customers", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "email",      limit: 255
    t.string   "phone",      limit: 255
    t.text     "comment"
    t.boolean  "subscribe",              default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profile_attributes", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "shop_id",    null: false
    t.jsonb    "value",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "profile_attributes", ["user_id"], name: "index_profile_attributes_on_user_id", using: :btree

  create_table "promotions", force: :cascade do |t|
    t.string   "brand",        null: false
    t.string   "categories",   null: false, array: true
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.date     "finishing_at"
  end

  create_table "recommendations_requests", id: false, force: :cascade do |t|
    t.integer  "id",                                default: 0,     null: false
    t.integer  "shop_id",                                           null: false
    t.integer  "category_id",                                       null: false
    t.string   "recommender_type",      limit: 255,                 null: false
    t.boolean  "clicked",                           default: false, null: false
    t.integer  "recommendations_count",                             null: false
    t.text     "recommended_ids",                   default: [],    null: false, array: true
    t.decimal  "duration",                                          null: false
    t.integer  "user_id"
    t.string   "session_code",          limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recommender_statistics", force: :cascade do |t|
    t.string   "efficiency", limit: 3000
    t.integer  "shop_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "recommender_statistics", ["shop_id"], name: "index_recommender_statistics_on_shop_id", using: :btree

  create_table "requisites", force: :cascade do |t|
    t.integer  "requisitable_id",                   null: false
    t.string   "requisitable_type",     limit: 255, null: false
    t.text     "name",                              null: false
    t.string   "inn",                   limit: 12,  null: false
    t.string   "kpp",                   limit: 9,   null: false
    t.text     "legal_address",                     null: false
    t.text     "mailing_address",                   null: false
    t.text     "bank_name",                         null: false
    t.string   "bik",                   limit: 9,   null: false
    t.string   "correspondent_account", limit: 20,  null: false
    t.string   "checking_account",      limit: 20,  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "requisites", ["requisitable_id", "requisitable_type"], name: "index_requisites_on_requisitable_id_and_requisitable_type", using: :btree

  create_table "rewards", force: :cascade do |t|
    t.integer  "manager_id",                           null: false
    t.integer  "customer_id",                          null: false
    t.integer  "transaction_id",                       null: false
    t.integer  "financial_manager_id"
    t.boolean  "paid",                 default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rewards", ["manager_id"], name: "index_rewards_on_manager_id", using: :btree

  create_table "sales_requests", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company"
    t.string   "website"
    t.string   "email"
    t.string   "mobile_phone"
    t.string   "work_phone"
    t.string   "city"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "schema_version", id: false, force: :cascade do |t|
    t.integer  "version_rank",                                                null: false
    t.integer  "installed_rank",                                              null: false
    t.string   "version",        limit: 50,                                   null: false
    t.string   "description",    limit: 200,                                  null: false
    t.string   "type",           limit: 20,                                   null: false
    t.string   "script",         limit: 1000,                                 null: false
    t.integer  "checksum"
    t.string   "installed_by",   limit: 100,                                  null: false
    t.datetime "installed_on",                default: '2015-06-11 10:16:12', null: false
    t.integer  "execution_time",                                              null: false
    t.boolean  "success",                                                     null: false
  end

  create_table "sessions", id: :bigserial, force: :cascade do |t|
    t.integer "user_id",   limit: 8,                  null: false
    t.string  "code",      limit: 255,                null: false
    t.boolean "is_active",             default: true
    t.string  "useragent", limit: 255
    t.string  "city",      limit: 255
    t.string  "country",   limit: 255
    t.string  "language",  limit: 255
  end

  add_index "sessions", ["code"], name: "sessions_uniqid_key", unique: true, using: :btree

  create_table "shop_days_statistics", force: :cascade do |t|
    t.integer "shop_id"
    t.decimal "natural"
    t.decimal "recommended"
    t.date    "date"
    t.integer "natural_count",     default: 0
    t.integer "recommended_count", default: 0
    t.text    "orders_info"
  end

  add_index "shop_days_statistics", ["shop_id"], name: "index_shop_days_statistics_on_shop_id", using: :btree

  create_table "shop_statistics", force: :cascade do |t|
    t.integer "shop_id"
    t.decimal "day_recommended"
    t.decimal "day_natural"
    t.decimal "week_recommended"
    t.decimal "week_natural"
    t.decimal "month_recommended"
    t.decimal "month_natural"
    t.integer "day_recommended_count",   default: 0
    t.integer "day_natural_count",       default: 0
    t.integer "week_recommended_count",  default: 0
    t.integer "week_natural_count",      default: 0
    t.integer "month_recommended_count", default: 0
    t.integer "month_natural_count",     default: 0
  end

  create_table "shops", id: :bigserial, force: :cascade do |t|
    t.string   "uniqid",                        limit: 255,                                         null: false
    t.string   "name",                          limit: 255,                                         null: false
    t.boolean  "active",                                                            default: true,  null: false
    t.integer  "customer_id"
    t.boolean  "connected",                                                         default: false
    t.string   "url",                           limit: 255
    t.boolean  "ab_testing"
    t.datetime "ab_testing_started_at"
    t.datetime "ab_testing_finished_at"
    t.string   "secret",                        limit: 255
    t.integer  "partner_id"
    t.datetime "connected_at"
    t.string   "mean_monthly_orders_count",     limit: 255
    t.integer  "category_id"
    t.boolean  "paid",                                                              default: false, null: false
    t.datetime "trial_ends_at"
    t.integer  "cms_id"
    t.string   "currency",                      limit: 255,                         default: "р."
    t.integer  "plan_id"
    t.boolean  "needs_to_pay",                                                      default: false, null: false
    t.datetime "paid_till"
    t.boolean  "manual",                                                            default: false, null: false
    t.boolean  "requested_ab_testing",                                              default: false, null: false
    t.decimal  "efficiency",                                precision: 5, scale: 2, default: 0.0,   null: false
    t.string   "yml_file_url",                  limit: 255
    t.boolean  "yml_loaded",                                                        default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tracked_monthly_orders_count",                                      default: 0,     null: false
    t.string   "rivals",                                                            default: [],                 array: true
    t.boolean  "has_orders_last_week",                                              default: false, null: false
    t.boolean  "strict_recommendations",                                            default: false, null: false
    t.decimal  "recommended_items_view_rate",                                       default: 0.0,   null: false
    t.boolean  "export_to_ct",                                                      default: false
    t.integer  "manager_id"
    t.boolean  "enable_nda",                                                        default: false
    t.boolean  "available_ibeacon",                                                 default: false
    t.boolean  "gives_rewards",                                                     default: true,  null: false
    t.boolean  "hopeless",                                                          default: false, null: false
    t.boolean  "sectoral_algorythms_available",                                     default: false, null: false
    t.boolean  "restricted",                                                        default: false, null: false
    t.decimal  "revenue_per_visit",                                                 default: 0.0,   null: false
    t.datetime "last_valid_yml_file_loaded_at"
    t.text     "connection_status_last_track"
    t.integer  "plan_value"
    t.boolean  "dont_disconnect",                                                   default: false, null: false
    t.string   "brb_address"
  end

  add_index "shops", ["cms_id"], name: "index_shops_on_cms_id", using: :btree
  add_index "shops", ["customer_id"], name: "index_shops_on_customer_id", using: :btree
  add_index "shops", ["manager_id"], name: "index_shops_on_manager_id", using: :btree
  add_index "shops", ["uniqid"], name: "shops_uniqid_key", unique: true, using: :btree

  create_table "styles", force: :cascade do |t|
    t.integer  "shop_id",                 null: false
    t.string   "shop_uniqid", limit: 255, null: false
    t.text     "css"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "styles", ["shop_id"], name: "index_styles_on_shop_id", unique: true, using: :btree
  add_index "styles", ["shop_uniqid"], name: "index_styles_on_shop_uniqid", unique: true, using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "shop_id",                                                       null: false
    t.integer  "user_id",                                                       null: false
    t.boolean  "active",                         default: true,                 null: false
    t.boolean  "declined",                       default: false,                null: false
    t.string   "email",              limit: 255
    t.string   "name",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "dont_disturb_until"
    t.uuid     "code",                           default: "uuid_generate_v4()"
  end

  add_index "subscriptions", ["shop_id", "user_id"], name: "index_subscriptions_on_shop_id_and_user_id", unique: true, using: :btree

  create_table "subscriptions_settings", force: :cascade do |t|
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
  end

  create_table "transactions", force: :cascade do |t|
    t.integer  "amount",                       default: 500, null: false
    t.integer  "transaction_type",             default: 0,   null: false
    t.string   "payment_method",   limit: 255,               null: false
    t.integer  "status",                       default: 0
    t.integer  "customer_id"
    t.datetime "processed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment"
    t.integer  "shop_id"
  end

  create_table "trigger_mailings", force: :cascade do |t|
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

  create_table "trigger_mails", force: :cascade do |t|
    t.integer  "shop_id",                                           null: false
    t.text     "trigger_data",                                      null: false
    t.uuid     "code",               default: "uuid_generate_v4()"
    t.boolean  "clicked",            default: false,                null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "opened",             default: false,                null: false
    t.integer  "trigger_mailing_id",                                null: false
    t.boolean  "bounced",            default: false,                null: false
    t.integer  "client_id",                                         null: false
  end

  add_index "trigger_mails", ["code"], name: "index_trigger_mails_on_code", unique: true, using: :btree
  add_index "trigger_mails", ["trigger_mailing_id"], name: "index_trigger_mails_on_trigger_mailing_id", using: :btree

  create_table "url_aliases", force: :cascade do |t|
    t.string   "pattern",    limit: 255, null: false
    t.string   "alias",      limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :bigserial, force: :cascade do |t|
    t.jsonb "gender", default: {"f"=>50, "m"=>50}, null: false
    t.jsonb "size",   default: {},                 null: false
  end

  add_foreign_key "actions", "shops", name: "actions_shop_id_fkey"
  add_foreign_key "items", "shops", name: "items_shop_id_fkey"
end
