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

ActiveRecord::Schema.define(version: 20160920115836) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "dblink"
  enable_extension "uuid-ossp"

  create_table "actions", id: :bigserial, force: :cascade do |t|
    t.integer  "user_id",          limit: 8,                 null: false
    t.integer  "item_id",          limit: 8,                 null: false
    t.integer  "view_count",                   default: 0,   null: false
    t.datetime "view_date"
    t.integer  "cart_count",                   default: 0,   null: false
    t.datetime "cart_date"
    t.integer  "purchase_count",               default: 0,   null: false
    t.datetime "purchase_date"
    t.float    "rating",                       default: 0.0
    t.integer  "shop_id",                                    null: false
    t.integer  "timestamp",                    default: 0,   null: false
    t.string   "recommended_by",   limit: 255
    t.integer  "last_action",      limit: 2,   default: 1,   null: false
    t.integer  "rate_count",                   default: 0,   null: false
    t.datetime "rate_date"
    t.integer  "last_user_rating"
    t.datetime "recommended_at"
  end

  add_index "actions", ["item_id"], name: "index_actions_on_item_id", using: :btree
  add_index "actions", ["shop_id", "item_id", "timestamp"], name: "popular_index_by_purchases", where: "(purchase_count > 0)", using: :btree
  add_index "actions", ["shop_id", "item_id", "timestamp"], name: "popular_index_by_rating", using: :btree
  add_index "actions", ["shop_id", "timestamp"], name: "buying_now_index", using: :btree
  add_index "actions", ["shop_id"], name: "index_actions_on_shop_id", using: :btree
  add_index "actions", ["user_id", "item_id"], name: "index_actions_on_user_id_and_item_id", unique: true, using: :btree
  add_index "actions", ["user_id"], name: "index_actions_on_user_id", using: :btree

  create_table "audience_segment_statistics", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "overall",             default: 0, null: false
    t.integer "activity_a",          default: 0, null: false
    t.integer "activity_b",          default: 0, null: false
    t.integer "activity_c",          default: 0, null: false
    t.date    "recalculated_at",                 null: false
    t.integer "triggers_overall",    default: 0, null: false
    t.integer "triggers_activity_a", default: 0, null: false
    t.integer "triggers_activity_b", default: 0, null: false
    t.integer "triggers_activity_c", default: 0, null: false
    t.integer "digests_overall",     default: 0, null: false
    t.integer "digests_activity_a",  default: 0, null: false
    t.integer "digests_activity_b",  default: 0, null: false
    t.integer "digests_activity_c",  default: 0, null: false
    t.integer "with_email",          default: 0, null: false
    t.integer "web_push_overall",    default: 0, null: false
  end

  add_index "audience_segment_statistics", ["shop_id"], name: "index_audience_segment_statistics_on_shop_id", unique: true, using: :btree

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

  create_table "catalog_import_logs", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "filesize",   default: 0,     null: false
    t.integer  "total",      default: 0,     null: false
    t.integer  "available",  default: 0,     null: false
    t.integer  "widgetable", default: 0,     null: false
    t.integer  "categories", default: 0,     null: false
    t.string   "message"
    t.boolean  "success",    default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
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
    t.integer  "shop_id",                                                                       null: false
    t.integer  "user_id",                            limit: 8,                                  null: false
    t.boolean  "bought_something",                               default: false,                null: false
    t.integer  "ab_testing_group"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "external_id",                        limit: 255
    t.string   "email",                              limit: 255
    t.boolean  "digests_enabled",                                default: true,                 null: false
    t.uuid     "code",                                           default: "uuid_generate_v4()"
    t.boolean  "subscription_popup_showed",                      default: false,                null: false
    t.boolean  "triggers_enabled",                               default: true,                 null: false
    t.datetime "last_trigger_mail_sent_at"
    t.boolean  "accepted_subscription",                          default: false,                null: false
    t.string   "location"
    t.date     "last_activity_at"
    t.integer  "activity_segment"
    t.boolean  "supply_trigger_sent"
    t.string   "web_push_token"
    t.string   "web_push_browser"
    t.boolean  "web_push_enabled"
    t.datetime "last_web_push_sent_at"
    t.boolean  "web_push_subscription_popup_showed"
    t.boolean  "accepted_web_push_subscription"
  end

  add_index "clients", ["code"], name: "index_clients_on_code", unique: true, using: :btree
  add_index "clients", ["digests_enabled", "shop_id"], name: "index_clients_on_digests_enabled_and_shop_id", using: :btree
  add_index "clients", ["email"], name: "index_clients_on_email", using: :btree
  add_index "clients", ["shop_id", "accepted_subscription"], name: "index_clients_on_shop_id_and_accepted_subscription", where: "((accepted_subscription IS TRUE) AND (subscription_popup_showed IS TRUE))", using: :btree
  add_index "clients", ["shop_id", "accepted_web_push_subscription"], name: "index_clients_on_shop_id_and_accepted_web_push_subscription", where: "((accepted_web_push_subscription IS TRUE) AND (web_push_subscription_popup_showed IS TRUE))", using: :btree
  add_index "clients", ["shop_id", "activity_segment"], name: "index_clients_on_shop_id_and_activity_segment", where: "(activity_segment IS NOT NULL)", using: :btree
  add_index "clients", ["shop_id", "external_id"], name: "index_clients_on_shop_id_and_external_id", where: "(external_id IS NOT NULL)", using: :btree
  add_index "clients", ["shop_id", "id"], name: "shops_users_shop_id_id_idx", where: "((email IS NOT NULL) AND (digests_enabled = true))", using: :btree
  add_index "clients", ["shop_id", "last_activity_at"], name: "index_clients_on_shop_id_and_last_activity_at", where: "(((email IS NOT NULL) AND (triggers_enabled IS TRUE)) AND (last_activity_at IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "last_trigger_mail_sent_at"], name: "idx_clients_shop_id_last_trigger_email_nulls_first", where: "((triggers_enabled = true) AND (email IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "subscription_popup_showed"], name: "index_clients_on_shop_id_and_subscription_popup_showed", where: "(subscription_popup_showed IS TRUE)", using: :btree
  add_index "clients", ["shop_id", "user_id"], name: "index_clients_on_shop_id_and_user_id", using: :btree
  add_index "clients", ["shop_id", "web_push_enabled", "last_web_push_sent_at"], name: "index_clients_last_web_push_sent_at", where: "((web_push_enabled IS TRUE) AND (last_web_push_sent_at IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "web_push_enabled"], name: "index_clients_on_shop_id_and_web_push_enabled", where: "(web_push_enabled IS TRUE)", using: :btree
  add_index "clients", ["shop_id", "web_push_subscription_popup_showed"], name: "index_clients_on_shop_id_and_web_push_subscription_popup_showed", where: "(web_push_subscription_popup_showed IS TRUE)", using: :btree
  add_index "clients", ["shop_id"], name: "index_clients_on_shop_id", using: :btree
  add_index "clients", ["triggers_enabled", "shop_id"], name: "index_clients_on_triggers_enabled_and_shop_id", using: :btree
  add_index "clients", ["user_id"], name: "index_clients_on_user_id", using: :btree

  create_table "digest_mailing_batches", id: :bigserial, force: :cascade do |t|
    t.integer "digest_mailing_id", limit: 8,                   null: false
    t.integer "end_id",            limit: 8
    t.boolean "completed",                     default: false, null: false
    t.integer "start_id",          limit: 8
    t.string  "test_email",        limit: 255
    t.integer "shop_id"
    t.integer "activity_segment"
    t.integer "mailchimp_count"
    t.integer "mailchimp_offset"
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
    t.integer  "shop_id",                                                    null: false
    t.string   "name",                        limit: 255,                    null: false
    t.string   "subject",                     limit: 255,                    null: false
    t.string   "items",                       limit: 255
    t.string   "state",                       limit: 255, default: "draft",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_mails_count"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text     "header"
    t.text     "text"
    t.string   "edit_mode",                   limit: 255, default: "simple", null: false
    t.integer  "activity_segment"
    t.text     "liquid_template"
    t.integer  "amount_of_recommended_items",             default: 9,        null: false
    t.integer  "image_width",                             default: 180
    t.integer  "image_height",                            default: 180
    t.string   "mailchimp_campaign_id"
    t.string   "mailchimp_list_id"
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
    t.date     "date"
  end

  add_index "digest_mails", ["client_id"], name: "index_digest_mails_on_client_id", using: :btree
  add_index "digest_mails", ["code"], name: "index_digest_mails_on_code", unique: true, using: :btree
  add_index "digest_mails", ["date", "shop_id"], name: "index_digest_mails_on_date_and_shop_id", using: :btree
  add_index "digest_mails", ["date"], name: "index_digest_mails_on_date", using: :btree
  add_index "digest_mails", ["digest_mailing_id"], name: "index_digest_mails_on_digest_mailing_id", using: :btree

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
    t.string   "taxonomy"
  end

  add_index "item_categories", ["shop_id", "external_id"], name: "index_item_categories_on_shop_id_and_external_id", unique: true, using: :btree
  add_index "item_categories", ["shop_id"], name: "index_item_categories_with_taxonomy", where: "(taxonomy IS NOT NULL)", using: :btree
  add_index "item_categories", ["shop_id"], name: "index_item_categories_without_taxonomy", where: "((taxonomy IS NULL) AND (name IS NOT NULL))", using: :btree

  create_table "items", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",                                              null: false
    t.string  "uniqid",                  limit: 255,                  null: false
    t.decimal "price"
    t.boolean "is_available",                         default: true,  null: false
    t.string  "name",                    limit: 255
    t.text    "description"
    t.text    "url"
    t.text    "image_url"
    t.boolean "widgetable",                           default: false, null: false
    t.string  "brand",                   limit: 255
    t.boolean "ignored",                              default: false, null: false
    t.jsonb   "locations",                            default: {},    null: false
    t.float   "sr"
    t.integer "sales_rate",              limit: 2
    t.string  "type_prefix"
    t.string  "vendor_code"
    t.string  "model"
    t.string  "fashion_gender",          limit: 1
    t.string  "fashion_wear_type",       limit: 20
    t.string  "fashion_feature",         limit: 20
    t.float   "child_age_min"
    t.float   "child_age_max"
    t.boolean "fmcg_hypoallergenic"
    t.string  "part_type",                                                         array: true
    t.string  "skin_type",                                                         array: true
    t.string  "condition",                                                         array: true
    t.jsonb   "fmcg_volume"
    t.boolean "fmcg_periodic"
    t.string  "barcode",                 limit: 1914
    t.string  "category_ids",                                                      array: true
    t.string  "location_ids",                                                      array: true
    t.integer "price_margin"
    t.string  "fashion_sizes",                                                     array: true
    t.string  "cosmetic_gender",         limit: 1
    t.boolean "cosmetic_hypoallergenic"
    t.string  "cosmetic_skin_part",                                                array: true
    t.string  "cosmetic_skin_type",                                                array: true
    t.string  "cosmetic_skin_condition",                                           array: true
    t.string  "cosmetic_hair_type",                                                array: true
    t.string  "cosmetic_hair_condition",                                           array: true
    t.jsonb   "cosmetic_volume"
    t.boolean "cosmetic_periodic"
    t.boolean "is_cosmetic"
    t.boolean "is_child"
    t.boolean "is_fashion"
    t.string  "child_gender",            limit: 1
    t.string  "child_type"
    t.boolean "is_fmcg"
    t.decimal "oldprice"
    t.string  "brand_downcase"
    t.boolean "discount"
  end

  add_index "items", ["brand"], name: "index_items_on_brand", where: "(brand IS NOT NULL)", using: :btree
  add_index "items", ["brand_downcase"], name: "index_items_on_brand_for_brand_campaign", where: "((brand_downcase IS NOT NULL) AND (category_ids IS NOT NULL))", using: :btree
  add_index "items", ["category_ids"], name: "index_items_on_category_ids", using: :gin
  add_index "items", ["category_ids"], name: "index_items_on_category_ids_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["fashion_sizes", "fashion_wear_type"], name: "index_items_on_sizes_recommendable", where: "(((is_available IS TRUE) AND (ignored IS FALSE)) AND ((fashion_sizes IS NOT NULL) AND (fashion_wear_type IS NOT NULL)))", using: :gin
  add_index "items", ["is_child"], name: "index_items_on_is_child", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["is_cosmetic"], name: "index_items_on_is_cosmetic", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["is_fashion"], name: "index_items_on_is_fashion", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["locations"], name: "index_items_on_locations", using: :gin
  add_index "items", ["locations"], name: "index_items_on_locations_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["price"], name: "index_items_on_price", where: "(((is_available = true) AND (ignored = false)) AND (price IS NOT NULL))", using: :btree
  add_index "items", ["shop_id", "discount"], name: "index_items_on_shop_id_and_discount", where: "(discount IS NOT NULL)", using: :btree
  add_index "items", ["shop_id", "fashion_gender"], name: "index_items_on_shop_id_and_fashion_gender", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id", "price_margin", "sales_rate"], name: "index_items_on_shop_id_and_price_margin_and_sales_rate", where: "(((price_margin IS NOT NULL) AND (is_available IS TRUE)) AND (ignored IS FALSE))", using: :btree
  add_index "items", ["shop_id", "sales_rate"], name: "available_items_with_sales_rate", where: "((((is_available = true) AND (ignored = false)) AND (sales_rate IS NOT NULL)) AND (sales_rate > 0))", using: :btree
  add_index "items", ["shop_id", "uniqid"], name: "index_items_on_shop_id_and_uniqid", unique: true, using: :btree
  add_index "items", ["shop_id"], name: "index_items_on_shop_id", using: :btree
  add_index "items", ["shop_id"], name: "shop_available_index", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id"], name: "widgetable_shop", where: "(((widgetable = true) AND (is_available = true)) AND (ignored = false))", using: :btree

  create_table "mailings_settings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                     null: false
    t.string   "send_from",           limit: 255,             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "logo_file_name",      limit: 255
    t.string   "logo_content_type",   limit: 255
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.integer  "mailing_service",                 default: 0
    t.string   "getresponse_api_key"
    t.string   "getresponse_api_url"
    t.integer  "template_type",                   default: 1
    t.string   "mailchimp_api_key"
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
    t.boolean  "compensated"
  end

  add_index "orders", ["date"], name: "index_orders_on_date", using: :btree
  add_index "orders", ["shop_id", "date"], name: "index_orders_on_shop_id_and_date", using: :btree
  add_index "orders", ["shop_id", "source_type", "date"], name: "index_orders_on_shop_id_and_source_type_and_date", where: "(source_type IS NOT NULL)", using: :btree
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

  add_index "recommendations_requests", ["shop_id"], name: "index_recommendations_requests_on_shop_id", using: :btree

  create_table "search_queries", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",           null: false
    t.integer "user_id", limit: 8, null: false
    t.date    "date",              null: false
    t.string  "query",             null: false
  end

  add_index "search_queries", ["shop_id", "query"], name: "index_search_queries_on_shop_id_and_query", using: :btree

  create_table "shop_metrics", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "orders",                             default: 0,   null: false
    t.integer "real_orders",                        default: 0,   null: false
    t.decimal "revenue",                            default: 0.0, null: false
    t.decimal "real_revenue",                       default: 0.0, null: false
    t.integer "visitors",                           default: 0,   null: false
    t.integer "products_viewed",                    default: 0,   null: false
    t.integer "triggers_enabled_count",             default: 0,   null: false
    t.integer "triggers_orders",                    default: 0,   null: false
    t.decimal "triggers_revenue",                   default: 0.0, null: false
    t.integer "digests_orders",                     default: 0,   null: false
    t.decimal "digests_revenue",                    default: 0.0, null: false
    t.integer "abandoned_products",                 default: 0,   null: false
    t.decimal "abandoned_money",                    default: 0.0, null: false
    t.date    "date",                                             null: false
    t.integer "triggers_sent",                      default: 0,   null: false
    t.integer "triggers_clicked",                   default: 0,   null: false
    t.decimal "triggers_revenue_real",              default: 0.0, null: false
    t.integer "triggers_orders_real",               default: 0,   null: false
    t.integer "digests_sent",                       default: 0,   null: false
    t.integer "digests_clicked",                    default: 0,   null: false
    t.decimal "digests_revenue_real",               default: 0.0, null: false
    t.integer "digests_orders_real",                default: 0,   null: false
    t.integer "subscription_popup_showed",          default: 0
    t.integer "subscription_accepted",              default: 0
    t.integer "orders_original_count",              default: 0
    t.decimal "orders_original_revenue",            default: 0.0
    t.integer "orders_recommended_count",           default: 0
    t.decimal "orders_recommended_revenue",         default: 0.0
    t.integer "product_views_total",                default: 0
    t.integer "product_views_recommended",          default: 0
    t.jsonb   "top_products",                                                  array: true
    t.jsonb   "products_statistics"
    t.integer "web_push_subscription_popup_showed", default: 0
    t.integer "web_push_subscription_accepted",     default: 0
  end

  add_index "shop_metrics", ["shop_id", "date"], name: "index_shop_metrics_on_shop_id_and_date", unique: true, using: :btree
  add_index "shop_metrics", ["shop_id"], name: "index_shop_metrics_on_shop_id", using: :btree

  create_table "subscribe_for_categories", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",          limit: 8
    t.integer  "item_category_id", limit: 8
    t.datetime "subscribed_at"
  end

  add_index "subscribe_for_categories", ["shop_id", "subscribed_at"], name: "index_category_subscription_for_cleanup", using: :btree
  add_index "subscribe_for_categories", ["shop_id", "user_id", "item_category_id"], name: "index_category_subscription_uniq", unique: true, using: :btree
  add_index "subscribe_for_categories", ["shop_id", "user_id"], name: "index_category_subscription_for_triggers", using: :btree

  create_table "subscribe_for_product_availables", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",       limit: 8
    t.integer  "item_id",       limit: 8
    t.datetime "subscribed_at"
  end

  add_index "subscribe_for_product_availables", ["shop_id", "user_id", "item_id"], name: "index_subscribe_for_product_available_uniq", unique: true, using: :btree
  add_index "subscribe_for_product_availables", ["shop_id", "user_id"], name: "index_subscribe_for_product_available_for_user", using: :btree

  create_table "subscribe_for_product_prices", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",       limit: 8
    t.integer  "item_id",       limit: 8
    t.datetime "subscribed_at"
    t.decimal  "price",                   null: false
  end

  add_index "subscribe_for_product_prices", ["shop_id", "user_id", "item_id"], name: "index_subscribe_for_product_price_uniq", unique: true, using: :btree
  add_index "subscribe_for_product_prices", ["shop_id", "user_id"], name: "index_subscribe_for_product_price_for_user", using: :btree

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
    t.string   "button"
    t.text     "agreement"
  end

  create_table "trigger_mailing_queues", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "user_id",           limit: 8
    t.string   "email"
    t.string   "trigger_type"
    t.datetime "triggered_at"
    t.string   "recommended_items",           array: true
    t.string   "source_items",                array: true
    t.string   "trigger_mail_code"
  end

  add_index "trigger_mailing_queues", ["shop_id"], name: "index_trigger_mailing_queues_on_shop_id", using: :btree
  add_index "trigger_mailing_queues", ["triggered_at"], name: "index_trigger_mailing_queues_on_triggered_at", using: :btree

  create_table "trigger_mailings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                 null: false
    t.string   "trigger_type",                limit: 255,                 null: false
    t.string   "subject",                     limit: 255,                 null: false
    t.boolean  "enabled",                                 default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "liquid_template"
    t.integer  "amount_of_recommended_items",             default: 9,     null: false
    t.integer  "image_width",                             default: 180
    t.integer  "image_height",                            default: 180
    t.string   "mailchimp_campaign_id"
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
    t.date     "date"
  end

  add_index "trigger_mails", ["code"], name: "index_trigger_mails_on_code", unique: true, using: :btree
  add_index "trigger_mails", ["date", "shop_id"], name: "index_trigger_mails_on_date_and_shop_id", using: :btree
  add_index "trigger_mails", ["date"], name: "index_trigger_mails_on_date", using: :btree
  add_index "trigger_mails", ["shop_id", "trigger_mailing_id"], name: "index_trigger_mails_on_shop_id_and_trigger_mailing_id", where: "(opened = false)", using: :btree
  add_index "trigger_mails", ["trigger_mailing_id"], name: "index_trigger_mails_on_trigger_mailing_id", using: :btree

  create_table "visits", force: :cascade do |t|
    t.date    "date",                          null: false
    t.integer "user_id", limit: 8,             null: false
    t.integer "shop_id",                       null: false
    t.integer "pages",             default: 1, null: false
  end

  add_index "visits", ["date", "user_id", "shop_id"], name: "index_visits_on_date_and_user_id_and_shop_id", unique: true, using: :btree
  add_index "visits", ["shop_id", "date"], name: "index_visits_on_shop_id_and_date", using: :btree

  create_table "web_push_digest_batches", id: :bigserial, force: :cascade do |t|
    t.integer "web_push_digest_id", limit: 8,                 null: false
    t.integer "end_id",             limit: 8
    t.boolean "completed",                    default: false, null: false
    t.integer "start_id",           limit: 8
    t.integer "shop_id"
  end

  add_index "web_push_digest_batches", ["shop_id"], name: "index_web_push_digest_batches_on_shop_id", using: :btree
  add_index "web_push_digest_batches", ["web_push_digest_id"], name: "index_web_push_digest_batches_on_web_push_digest_id", using: :btree

  create_table "web_push_digest_messages", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                           null: false
    t.uuid     "code",                               default: "uuid_generate_v4()"
    t.boolean  "clicked",                            default: false,                null: false
    t.integer  "web_push_digest_id",       limit: 8,                                null: false
    t.boolean  "unsubscribed",                       default: false,                null: false
    t.integer  "client_id",                limit: 8,                                null: false
    t.date     "date"
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.integer  "web_push_digest_batch_id", limit: 8,                                null: false
  end

  add_index "web_push_digest_messages", ["code"], name: "index_web_push_digest_messages_on_code", unique: true, using: :btree
  add_index "web_push_digest_messages", ["date", "shop_id"], name: "index_web_push_digest_messages_on_date_and_shop_id", using: :btree
  add_index "web_push_digest_messages", ["date"], name: "index_web_push_digest_messages_on_date", using: :btree
  add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_web_push_trigger_id", where: "(clicked IS TRUE)", using: :btree
  add_index "web_push_digest_messages", ["web_push_digest_id"], name: "index_web_push_digest_messages_on_web_push_digest_id", using: :btree

  create_table "web_push_digests", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                             null: false
    t.string   "subject",              limit: 255,                    null: false
    t.string   "state",                limit: 255,  default: "draft", null: false
    t.integer  "total_mails_count"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.string   "message",              limit: 125
    t.string   "url",                  limit: 4096
  end

  add_index "web_push_digests", ["shop_id"], name: "index_web_push_digests_on_shop_id", using: :btree

  create_table "web_push_subscriptions_settings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                              null: false
    t.boolean  "enabled",                              default: false, null: false
    t.boolean  "overlay",                              default: true,  null: false
    t.text     "header",                                               null: false
    t.text     "text",                                                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "picture_file_name",        limit: 255
    t.string   "picture_content_type",     limit: 255
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.text     "css"
    t.string   "button"
    t.text     "agreement"
    t.boolean  "manual_mode",                          default: false
    t.string   "safari_website_push_id"
    t.string   "certificate_password"
    t.string   "certificate_file_name"
    t.string   "certificate_content_type"
    t.integer  "certificate_file_size"
    t.datetime "certificate_updated_at"
  end

  create_table "web_push_trigger_messages", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                      null: false
    t.text     "trigger_data",                                                 null: false
    t.uuid     "code",                          default: "uuid_generate_v4()"
    t.boolean  "clicked",                       default: false,                null: false
    t.integer  "web_push_trigger_id", limit: 8,                                null: false
    t.boolean  "unsubscribed",                  default: false,                null: false
    t.integer  "client_id",           limit: 8,                                null: false
    t.date     "date"
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
  end

  add_index "web_push_trigger_messages", ["code"], name: "index_web_push_trigger_messages_on_code", unique: true, using: :btree
  add_index "web_push_trigger_messages", ["date", "shop_id"], name: "index_web_push_trigger_messages_on_date_and_shop_id", using: :btree
  add_index "web_push_trigger_messages", ["date"], name: "index_web_push_trigger_messages_on_date", using: :btree
  add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], name: "index_web_push_trigger_msg_on_shop_id_and_web_push_trigger_id", where: "(clicked IS TRUE)", using: :btree
  add_index "web_push_trigger_messages", ["web_push_trigger_id"], name: "index_web_push_trigger_messages_on_web_push_trigger_id", using: :btree

  create_table "web_push_triggers", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                  null: false
    t.string   "trigger_type", limit: 255,                 null: false
    t.string   "subject",      limit: 255,                 null: false
    t.boolean  "enabled",                  default: false, null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "message",      limit: 125
  end

end
