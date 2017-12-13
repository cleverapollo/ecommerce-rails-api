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

ActiveRecord::Schema.define(version: 20171213052820) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "dblink"
  enable_extension "intarray"
  enable_extension "postgres_fdw"
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
  add_index "actions", ["user_id", "item_id"], name: "index_actions_on_user_id_and_item_id", unique: true, using: :btree

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

  create_table "advertiser_vendors", force: :cascade do |t|
    t.integer  "advertiser_id"
    t.integer  "vendor_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "advertiser_vendors", ["vendor_id", "advertiser_id"], name: "index_advertiser_vendors_on_vendor_id_and_advertiser_id", unique: true, using: :btree

  create_table "advertisers", force: :cascade do |t|
    t.string   "email"
    t.string   "encrypted_password",     default: "",  null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,   null: false
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
    t.float    "balance",                default: 0.0, null: false
    t.string   "brand"
    t.jsonb    "invitation_tokens",      default: {}
  end

  add_index "advertisers", ["email"], name: "index_advertisers_on_email", unique: true, using: :btree
  add_index "advertisers", ["reset_password_token"], name: "index_advertisers_on_reset_password_token", unique: true, using: :btree

  create_table "audience_segment_statistics", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "overall",               default: 0, null: false
    t.integer "activity_a",            default: 0, null: false
    t.integer "activity_b",            default: 0, null: false
    t.integer "activity_c",            default: 0, null: false
    t.date    "recalculated_at",                   null: false
    t.integer "triggers_overall",      default: 0, null: false
    t.integer "triggers_activity_a",   default: 0, null: false
    t.integer "triggers_activity_b",   default: 0, null: false
    t.integer "triggers_activity_c",   default: 0, null: false
    t.integer "digests_overall",       default: 0, null: false
    t.integer "digests_activity_a",    default: 0, null: false
    t.integer "digests_activity_b",    default: 0, null: false
    t.integer "digests_activity_c",    default: 0, null: false
    t.integer "with_email",            default: 0, null: false
    t.integer "web_push_overall",      default: 0, null: false
    t.integer "with_email_activity_a", default: 0, null: false
    t.integer "with_email_activity_b", default: 0, null: false
    t.integer "with_email_activity_c", default: 0, null: false
    t.integer "web_push_activity_a",   default: 0, null: false
    t.integer "web_push_activity_b",   default: 0, null: false
    t.integer "web_push_activity_c",   default: 0, null: false
  end

  add_index "audience_segment_statistics", ["shop_id"], name: "index_audience_segment_statistics_on_shop_id", unique: true, using: :btree

  create_table "brand_campaign_item_categories", force: :cascade do |t|
    t.integer  "item_category_id",  limit: 8
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "brand_campaign_id"
  end

  add_index "brand_campaign_item_categories", ["brand_campaign_id"], name: "index_brand_campaign_item_categories_on_brand_campaign_id", using: :btree
  add_index "brand_campaign_item_categories", ["item_category_id"], name: "index_brand_campaign_item_categories_on_item_category_id", using: :btree

  create_table "brand_campaign_purchases", force: :cascade do |t|
    t.integer  "item_id",           limit: 8
    t.integer  "shop_id"
    t.integer  "order_id",          limit: 8
    t.float    "price"
    t.string   "recommended_by"
    t.date     "date"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "brand_campaign_id"
  end

  add_index "brand_campaign_purchases", ["brand_campaign_id", "shop_id"], name: "index_brand_campaign_purchases_on_brand_campaign_id_and_shop_id", using: :btree
  add_index "brand_campaign_purchases", ["brand_campaign_id"], name: "index_brand_campaign_purchases_on_brand_campaign_id", using: :btree

  create_table "brand_campaign_shops", force: :cascade do |t|
    t.integer  "shop_id"
    t.datetime "last_event_at"
    t.integer  "brand_campaign_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "brand_campaign_shops", ["brand_campaign_id"], name: "index_brand_campaign_shops_on_brand_campaign_id", using: :btree
  add_index "brand_campaign_shops", ["shop_id"], name: "index_brand_campaign_shops_on_shop_id", using: :btree

  create_table "brand_campaign_statistics", force: :cascade do |t|
    t.integer  "views",                 default: 0,   null: false
    t.integer  "original_purchases",    default: 0,   null: false
    t.integer  "recommended_purchases", default: 0,   null: false
    t.float    "cost",                  default: 0.0, null: false
    t.date     "date",                                null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "recommended_clicks",    default: 0,   null: false
    t.integer  "original_clicks",       default: 0,   null: false
    t.integer  "brand_campaign_id"
  end

  add_index "brand_campaign_statistics", ["brand_campaign_id", "date"], name: "index_brand_campaign_statistics_on_brand_campaign_id_and_date", unique: true, using: :btree

  create_table "brand_campaign_statistics_events", force: :cascade do |t|
    t.integer  "brand_campaign_statistic_id",                 null: false
    t.integer  "brand_campaign_shop_id",                      null: false
    t.string   "recommender"
    t.string   "event",                                       null: false
    t.boolean  "recommended",                 default: false, null: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "brand_campaign_statistics_events", ["brand_campaign_statistic_id", "brand_campaign_shop_id", "recommended", "event"], name: "index_brand_campaign_statistics_events_campaign_and_shop", using: :btree

  create_table "brand_campaigns", force: :cascade do |t|
    t.integer  "advertiser_id"
    t.float    "balance",               default: 0.0,   null: false
    t.integer  "cpm",                   default: 1500,  null: false
    t.string   "brand",                                 null: false
    t.string   "downcase_brand",                        null: false
    t.boolean  "campaign_launched",     default: false, null: false
    t.integer  "priority",              default: 100,   null: false
    t.float    "cpc",                   default: 10.0,  null: false
    t.boolean  "is_expansion",          default: false
    t.integer  "campaign_type",         default: 1
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "product_minimum_price", default: 0,     null: false
    t.boolean  "in_all_categories",     default: false
  end

  create_table "brands", force: :cascade do |t|
    t.string   "name"
    t.string   "keyword"
    t.text     "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "categories", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.boolean  "deletable",                   default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code",            limit: 255,                null: false
    t.decimal  "increase_units"
    t.decimal  "increase_rubles"
    t.string   "taxonomy"
  end

  add_index "categories", ["code"], name: "index_categories_on_code", unique: true, using: :btree

  create_table "client_carts", id: :bigserial, force: :cascade do |t|
    t.integer  "user_id",    limit: 8, null: false
    t.integer  "shop_id",              null: false
    t.jsonb    "items"
    t.date     "date"
    t.string   "segments",                          array: true
    t.datetime "updated_at"
  end

  add_index "client_carts", ["date"], name: "index_client_carts_on_date", using: :btree
  add_index "client_carts", ["shop_id", "user_id"], name: "index_client_carts_on_shop_id_and_user_id", unique: true, using: :btree
  add_index "client_carts", ["user_id"], name: "index_client_carts_on_user_id", using: :btree

  create_table "client_errors", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "exception_class",   limit: 255,                 null: false
    t.text     "exception_message",                             null: false
    t.text     "params",                                        null: false
    t.boolean  "resolved",                      default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "referer",           limit: 255
  end

  add_index "client_errors", ["shop_id"], name: "index_client_errors_on_shop_id", where: "(resolved = false)", using: :btree

  create_table "clients", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                                                            null: false
    t.integer  "user_id",                                 limit: 8,                                  null: false
    t.boolean  "bought_something",                                    default: false,                null: false
    t.integer  "ab_testing_group"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "external_id",                             limit: 255
    t.string   "email",                                   limit: 255
    t.boolean  "digests_enabled",                                     default: true,                 null: false
    t.uuid     "code",                                                default: "uuid_generate_v4()"
    t.boolean  "subscription_popup_showed",                           default: false,                null: false
    t.boolean  "triggers_enabled",                                    default: true,                 null: false
    t.datetime "last_trigger_mail_sent_at"
    t.boolean  "accepted_subscription",                               default: false,                null: false
    t.string   "location"
    t.date     "last_activity_at"
    t.boolean  "supply_trigger_sent"
    t.boolean  "web_push_enabled"
    t.datetime "last_web_push_sent_at"
    t.boolean  "web_push_subscription_popup_showed"
    t.boolean  "accepted_web_push_subscription"
    t.integer  "fb_id",                                   limit: 8
    t.integer  "vk_id",                                   limit: 8
    t.boolean  "email_confirmed"
    t.integer  "segment_ids",                                                                                     array: true
    t.boolean  "digest_opened"
    t.date     "synced_with_republer_at"
    t.date     "synced_with_advmaker_at"
    t.date     "synced_with_doubleclick_at"
    t.date     "synced_with_doubleclick_cart_at"
    t.date     "synced_with_facebook_at"
    t.date     "synced_with_facebook_cart_at"
    t.string   "audience_sources"
    t.text     "external_audience_sources"
    t.boolean  "web_push_subscription_permission_showed"
  end

  add_index "clients", ["code"], name: "index_clients_on_code", unique: true, using: :btree
  add_index "clients", ["email", "shop_id", "id"], name: "index_clients_on_email", order: {"id"=>:desc}, where: "(email IS NOT NULL)", using: :btree
  add_index "clients", ["shop_id", "email", "digests_enabled", "id"], name: "index_clients_on_shop_id_and_digests_enabled", where: "((email IS NOT NULL) AND (digests_enabled = true))", using: :btree
  add_index "clients", ["shop_id", "email", "triggers_enabled", "id"], name: "index_clients_on_shop_id_and_triggers_enabled", where: "((email IS NOT NULL) AND (triggers_enabled = true))", using: :btree
  add_index "clients", ["shop_id", "email_confirmed", "id"], name: "index_clients_on_shop_id_and_email_confirmed", where: "(email IS NOT NULL)", using: :btree
  add_index "clients", ["shop_id", "external_id"], name: "index_clients_on_shop_id_and_external_id", where: "(external_id IS NOT NULL)", using: :btree
  add_index "clients", ["shop_id", "id"], name: "index_client_on_shop_id_and_email_present", order: {"id"=>:desc}, where: "(email IS NOT NULL)", using: :btree
  add_index "clients", ["shop_id", "last_activity_at", "last_trigger_mail_sent_at"], name: "index_clients_on_shop_id_and_last_activity_at", where: "((email IS NOT NULL) AND (triggers_enabled = true) AND (last_activity_at IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "last_web_push_sent_at", "id"], name: "index_clients_on_shop_id_and_web_push_enabled", where: "(web_push_enabled = true)", using: :btree
  add_index "clients", ["shop_id", "segment_ids"], name: "index_clients_on_shop_id_and_segment_ids", where: "(segment_ids IS NOT NULL)", using: :gin
  add_index "clients", ["shop_id", "subscription_popup_showed", "accepted_subscription"], name: "index_clients_on_shop_id_and_accepted_subscription", where: "((subscription_popup_showed = true) AND (accepted_subscription = true))", using: :btree
  add_index "clients", ["shop_id", "subscription_popup_showed"], name: "index_clients_on_shop_id_and_subscription_popup_showed", where: "(subscription_popup_showed = true)", using: :btree
  add_index "clients", ["shop_id", "user_id"], name: "index_clients_on_shop_id_and_user_id", using: :btree
  add_index "clients", ["shop_id", "vk_id", "fb_id"], name: "index_clients_on_social_merge", where: "((vk_id IS NOT NULL) OR (fb_id IS NOT NULL))", using: :btree
  add_index "clients", ["shop_id", "web_push_subscription_permission_showed"], name: "index_clients_on_shop_id_and_web_push_subscription_perm_showed", where: "(web_push_subscription_permission_showed = true)", using: :btree
  add_index "clients", ["shop_id", "web_push_subscription_popup_showed"], name: "index_clients_on_shop_id_and_web_push_subscription_popup_showed", where: "(web_push_subscription_popup_showed = true)", using: :btree
  add_index "clients", ["user_id"], name: "index_clients_on_user_id", using: :btree

  create_table "cmses", force: :cascade do |t|
    t.string   "code",               limit: 255,                 null: false
    t.string   "name",               limit: 255,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "supported",                      default: false, null: false
    t.string   "documentation_link", limit: 255
  end

  create_table "cpa_invoices", force: :cascade do |t|
    t.integer "shop_id"
    t.date    "date"
    t.float   "amount"
  end

  add_index "cpa_invoices", ["shop_id", "date"], name: "index_cpa_invoices_on_shop_id_and_date", using: :btree

  create_table "create_segment_changes_logs", force: :cascade do |t|
    t.integer  "session_id",       limit: 8, null: false
    t.string   "ssid"
    t.string   "segment"
    t.string   "segment_previous"
    t.string   "page"
    t.string   "user_agent"
    t.string   "label"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "create_segment_changes_logs", ["label"], name: "index_create_segment_changes_logs_on_label", where: "((label IS NOT NULL) AND ((label)::text <> 'initial'::text))", using: :btree

  create_table "currencies", force: :cascade do |t|
    t.string   "code",                                  null: false
    t.string   "symbol",                                null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "min_payment",           default: 500,   null: false
    t.float    "exchange_rate",         default: 1.0,   null: false
    t.boolean  "payable",               default: false
    t.boolean  "stripe_paid",           default: false, null: false
    t.float    "remarketing_min_price", default: 0.0,   null: false
  end

  add_index "currencies", ["stripe_paid"], name: "index_currencies_on_stripe_paid", using: :btree

  create_table "customer_balance_histories", force: :cascade do |t|
    t.integer  "customer_id"
    t.string   "message"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "customers", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",       null: false
    t.string   "encrypted_password",     limit: 255, default: "",       null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,        null: false
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
    t.boolean  "subscribed",                         default: true,     null: false
    t.string   "unsubscribe_token",      limit: 255
    t.integer  "partner_id"
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.float    "balance",                            default: 0.0,      null: false
    t.string   "gift_link",              limit: 255
    t.boolean  "real",                               default: true
    t.boolean  "financial_manager",                  default: false
    t.date     "recent_activity"
    t.string   "promocode"
    t.string   "juridical_person"
    t.integer  "currency_id",                        default: 1,        null: false
    t.string   "language",                           default: "en",     null: false
    t.boolean  "notify_about_finances",              default: true,     null: false
    t.integer  "partner_balance",                    default: 0,        null: false
    t.integer  "my_partner_visits",                  default: 0
    t.integer  "my_partner_signups",                 default: 0
    t.string   "api_key",                limit: 255
    t.string   "api_secret",             limit: 255
    t.string   "quick_sign_in_token"
    t.datetime "confirmed_at"
    t.string   "stripe_customer_id"
    t.string   "stripe_card_last4"
    t.string   "stripe_card_id"
    t.string   "country_code"
    t.string   "time_zone",                          default: "Moscow", null: false
    t.boolean  "shopify",                            default: false,    null: false
  end

  add_index "customers", ["api_key", "api_secret"], name: "index_customers_on_api_key_and_api_secret", unique: true, using: :btree
  add_index "customers", ["email"], name: "index_customers_on_email", unique: true, using: :btree
  add_index "customers", ["quick_sign_in_token"], name: "index_customers_on_quick_sign_in_token", using: :btree
  add_index "customers", ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true, using: :btree
  add_index "customers", ["stripe_customer_id"], name: "index_customers_on_stripe_customer_id", using: :btree

  create_table "digest_mail_statistics", force: :cascade do |t|
    t.date     "date",                   null: false
    t.integer  "shop_id",                null: false
    t.integer  "opened",     default: 0, null: false
    t.integer  "clicked",    default: 0, null: false
    t.integer  "bounced",    default: 0, null: false
    t.integer  "sent",       default: 0, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "digest_mail_statistics", ["date"], name: "index_digest_mail_statistics_on_date", using: :btree
  add_index "digest_mail_statistics", ["shop_id", "date"], name: "index_digest_mail_statistics_on_shop_id_and_date", unique: true, using: :btree
  add_index "digest_mail_statistics", ["shop_id"], name: "index_digest_mail_statistics_on_shop_id", using: :btree

  create_table "digest_mailing_batches", id: :bigserial, force: :cascade do |t|
    t.integer "digest_mailing_id", limit: 8,                   null: false
    t.integer "end_id",            limit: 8
    t.boolean "completed",                     default: false, null: false
    t.integer "start_id",          limit: 8
    t.string  "test_email",        limit: 255
    t.integer "shop_id"
    t.integer "mailchimp_count"
    t.integer "mailchimp_offset"
    t.integer "segment_id"
    t.integer "client_ids",        limit: 8,                                array: true
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
    t.text     "text_template"
    t.string   "edit_mode",                   limit: 255, default: "simple", null: false
    t.text     "liquid_template"
    t.integer  "amount_of_recommended_items",             default: 9,        null: false
    t.string   "mailchimp_campaign_id"
    t.string   "mailchimp_list_id"
    t.integer  "images_dimension",                        default: 3
    t.integer  "theme_id",                    limit: 8
    t.string   "theme_type"
    t.jsonb    "template_data"
    t.string   "intro_text"
    t.integer  "segment_id"
    t.datetime "planing_at"
    t.jsonb    "statistic"
    t.string   "job_id"
  end

  add_index "digest_mailings", ["shop_id", "theme_id", "theme_type"], name: "index_digest_mailings_theme", using: :btree
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
    t.integer  "click_map",                                                                     array: true
    t.integer  "bounce_reason",           limit: 2
    t.boolean  "unsubscribed"
  end

  add_index "digest_mails", ["client_id"], name: "index_digest_mails_on_client_id", using: :btree
  add_index "digest_mails", ["code"], name: "index_digest_mails_on_code", unique: true, using: :btree
  add_index "digest_mails", ["date", "shop_id"], name: "index_digest_mails_on_date_and_shop_id", using: :btree
  add_index "digest_mails", ["digest_mailing_id", "date"], name: "index_digest_mails_on_digest_mailing_id", using: :btree

  create_table "employees", force: :cascade do |t|
    t.integer  "customer_id",      null: false
    t.integer  "shop_id",          null: false
    t.integer  "head_customer_id", null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

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

  create_table "experiments", force: :cascade do |t|
    t.integer  "shop_id",                    null: false
    t.string   "name",                       null: false
    t.integer  "segments",   default: 2,     null: false
    t.boolean  "active",     default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
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

  create_table "instant_auth_tokens", force: :cascade do |t|
    t.integer "customer_id"
    t.string  "token"
    t.date    "date"
  end

  add_index "instant_auth_tokens", ["date"], name: "index_instant_auth_tokens_on_date", using: :btree
  add_index "instant_auth_tokens", ["token"], name: "index_instant_auth_tokens_on_token", unique: true, using: :btree

  create_table "interactions", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                    null: false
    t.integer  "user_id",          limit: 8, null: false
    t.integer  "item_id",          limit: 8, null: false
    t.integer  "code",                       null: false
    t.integer  "recommender_code"
    t.datetime "created_at",                 null: false
    t.string   "segments",                                array: true
  end

  add_index "interactions", ["shop_id", "created_at", "recommender_code"], name: "interactions_shop_id_created_at_recommender_code_idx", where: "(code = 1)", using: :btree
  add_index "interactions", ["user_id"], name: "index_interactions_on_user_id", using: :btree

  create_table "invalid_emails", force: :cascade do |t|
    t.string   "email",      null: false
    t.string   "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "invalid_emails", ["email"], name: "index_invalid_emails_on_email", unique: true, using: :btree

  create_table "ipn_messages", force: :cascade do |t|
    t.text     "content",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "item_categories", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                      null: false
    t.integer  "parent_id",          limit: 8
    t.string   "external_id",                  null: false
    t.string   "parent_external_id"
    t.string   "name"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "taxonomy"
    t.string   "url"
  end

  add_index "item_categories", ["shop_id", "external_id"], name: "index_item_categories_on_shop_id_and_external_id", unique: true, using: :btree
  add_index "item_categories", ["shop_id", "url"], name: "index_item_categories_with_url", where: "(url IS NOT NULL)", using: :btree
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
    t.boolean "is_auto"
    t.jsonb   "auto_compatibility"
    t.boolean "auto_periodic"
    t.text    "auto_vds",                                                          array: true
    t.boolean "is_pets"
    t.string  "pets_breed"
    t.string  "pets_type"
    t.string  "pets_age"
    t.boolean "pets_periodic"
    t.string  "pets_size"
    t.string  "image_downloading_error"
    t.boolean "is_jewelry"
    t.string  "jewelry_gender"
    t.string  "jewelry_color"
    t.string  "jewelry_metal"
    t.string  "jewelry_gem"
    t.jsonb   "ring_sizes"
    t.jsonb   "bracelet_sizes"
    t.jsonb   "chain_sizes"
    t.integer "seasonality",                                                       array: true
    t.boolean "cosmetic_nail"
    t.string  "cosmetic_nail_type"
    t.string  "cosmetic_nail_color"
    t.boolean "cosmetic_professional"
    t.string  "leftovers"
    t.string  "cosmetic_perfume_family"
    t.string  "cosmetic_perfume_aroma"
    t.string  "shop_recommend",                                                    array: true
    t.boolean "is_realty"
    t.string  "realty_type"
    t.float   "realty_space_min"
    t.float   "realty_space_max"
    t.float   "realty_space_final"
    t.string  "realty_action"
  end

  add_index "items", ["bracelet_sizes"], name: "index_items_on_bracelet_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (bracelet_sizes IS NOT NULL))", using: :gin
  add_index "items", ["brand"], name: "index_items_on_brand", where: "(brand IS NOT NULL)", using: :btree
  add_index "items", ["brand_downcase"], name: "index_items_on_brand_for_brand_campaign", where: "((brand_downcase IS NOT NULL) AND (category_ids IS NOT NULL))", using: :btree
  add_index "items", ["category_ids"], name: "index_items_on_category_ids", using: :gin
  add_index "items", ["category_ids"], name: "index_items_on_category_ids_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["chain_sizes"], name: "index_items_on_chain_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (chain_sizes IS NOT NULL))", using: :gin
  add_index "items", ["fashion_sizes", "fashion_wear_type"], name: "index_items_on_sizes_recommendable", where: "((is_available IS TRUE) AND (ignored IS FALSE) AND ((fashion_sizes IS NOT NULL) AND (fashion_wear_type IS NOT NULL)))", using: :gin
  add_index "items", ["jewelry_color"], name: "index_items_on_jewelry_color", where: "((is_jewelry IS TRUE) AND (jewelry_color IS NOT NULL) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["jewelry_gem"], name: "index_items_on_jewelry_gem", where: "((is_jewelry IS TRUE) AND (jewelry_gem IS NOT NULL) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["jewelry_gender"], name: "index_items_on_jewelry_gender", where: "((is_jewelry IS TRUE) AND (jewelry_gender IS NOT NULL) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["jewelry_metal"], name: "index_items_on_jewelry_metal", where: "((is_jewelry IS TRUE) AND (jewelry_metal IS NOT NULL) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["locations"], name: "index_items_on_locations", using: :gin
  add_index "items", ["locations"], name: "index_items_on_locations_recommendable", where: "((is_available = true) AND (ignored = false))", using: :gin
  add_index "items", ["pets_age"], name: "index_items_on_pets_age", where: "((is_pets IS TRUE) AND (pets_age IS NOT NULL))", using: :btree
  add_index "items", ["pets_breed"], name: "index_items_on_pets_breed", where: "((is_pets IS TRUE) AND (pets_breed IS NOT NULL))", using: :btree
  add_index "items", ["pets_size"], name: "index_items_on_pets_size", where: "((is_pets IS TRUE) AND (pets_size IS NOT NULL))", using: :btree
  add_index "items", ["pets_type"], name: "index_items_on_pets_type", where: "((is_pets IS TRUE) AND (pets_type IS NOT NULL))", using: :btree
  add_index "items", ["realty_action"], name: "index_items_on_realty_action", where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_action IS NOT NULL))", using: :btree
  add_index "items", ["realty_space_final"], name: "index_items_on_realty_space_final", where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_space_final IS NOT NULL))", using: :btree
  add_index "items", ["realty_space_max"], name: "index_items_on_realty_space_max", where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_space_max IS NOT NULL))", using: :btree
  add_index "items", ["realty_space_min"], name: "index_items_on_realty_space_min", where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_space_min IS NOT NULL))", using: :btree
  add_index "items", ["realty_type"], name: "index_items_on_realty_type", where: "((is_available = true) AND (ignored = false) AND (is_realty IS TRUE) AND (realty_type IS NOT NULL))", using: :btree
  add_index "items", ["ring_sizes"], name: "index_items_on_ring_sizes", where: "((is_available = true) AND (ignored = false) AND (is_jewelry IS TRUE) AND (ring_sizes IS NOT NULL))", using: :gin
  add_index "items", ["shop_id", "brand", "id"], name: "index_items_on_shop_and_brand", where: "((is_available = true) AND (ignored = false) AND (widgetable = true) AND (brand IS NOT NULL))", using: :btree
  add_index "items", ["shop_id", "brand_downcase", "id"], name: "index_items_on_shop_and_brand_downcase", where: "((is_available = true) AND (ignored = false) AND (widgetable = true) AND (brand_downcase IS NOT NULL))", using: :btree
  add_index "items", ["shop_id", "discount"], name: "index_items_on_shop_id_and_discount", where: "(discount IS NOT NULL)", using: :btree
  add_index "items", ["shop_id", "fashion_gender"], name: "index_items_on_shop_id_and_fashion_gender", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id", "id"], name: "widgetable_shop", where: "((widgetable = true) AND (is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id", "ignored"], name: "index_items_on_shop_id_and_ignored", where: "(ignored = true)", using: :btree
  add_index "items", ["shop_id", "image_downloading_error"], name: "index_items_on_shop_id_and_image_downloading_error", where: "(image_downloading_error IS NOT NULL)", using: :btree
  add_index "items", ["shop_id", "is_available", "ignored", "id"], name: "shop_available_index", where: "((is_available = true) AND (ignored = false))", using: :btree
  add_index "items", ["shop_id", "price"], name: "index_items_on_price", where: "((is_available = true) AND (ignored = false) AND (price IS NOT NULL))", using: :btree
  add_index "items", ["shop_id", "price_margin", "sales_rate"], name: "index_items_on_shop_id_and_price_margin_and_sales_rate", where: "((price_margin IS NOT NULL) AND (is_available IS TRUE) AND (ignored IS FALSE))", using: :btree
  add_index "items", ["shop_id", "sales_rate"], name: "available_items_with_sales_rate", where: "((is_available = true) AND (ignored = false) AND (sales_rate IS NOT NULL) AND (sales_rate > 0))", using: :btree
  add_index "items", ["shop_id", "uniqid"], name: "index_items_on_shop_id_and_uniqid", unique: true, using: :btree
  add_index "items", ["shop_id", "uniqid"], name: "index_items_on_shop_id_and_uniqid_and_is_available", where: "(is_available = true)", using: :btree

  create_table "leads", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "phone"
    t.string   "country"
    t.string   "city"
    t.string   "source"
    t.string   "comment"
    t.string   "website"
    t.string   "company"
    t.string   "position"
    t.boolean  "synced_with_crm",     default: false
    t.boolean  "success",             default: false
    t.boolean  "cancelled",           default: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "cms"
    t.string   "preferred_time_from"
    t.string   "preferred_time_to"
    t.string   "time_zone"
    t.integer  "shop_id"
    t.integer  "customer_id"
    t.string   "utm_source"
    t.string   "utm_medium"
    t.string   "utm_campaign"
  end

  create_table "mail_ru_audience_pools", force: :cascade do |t|
    t.string "list"
    t.string "session"
  end

  add_index "mail_ru_audience_pools", ["list"], name: "index_mail_ru_audience_pools_on_list", using: :btree

  create_table "mailings_settings", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                     null: false
    t.string   "send_from",           limit: 255,             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "mailing_service",                 default: 0
    t.string   "getresponse_api_key"
    t.string   "mailchimp_api_key"
    t.string   "unsubscribe_message"
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

  create_table "no_result_queries", force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "query"
    t.string   "synonym"
    t.integer  "query_count", default: 1
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "no_result_queries", ["shop_id", "query"], name: "index_no_result_queries_on_shop_id_and_query", unique: true, using: :btree
  add_index "no_result_queries", ["synonym"], name: "index_no_result_queries_on_synonym", using: :btree

  create_table "order_items", id: :bigserial, force: :cascade do |t|
    t.integer "order_id",       limit: 8,               null: false
    t.integer "item_id",        limit: 8,               null: false
    t.integer "action_id",      limit: 8
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
    t.string   "reputation_key"
    t.string   "segments",                                                   array: true
    t.string   "segment_ds"
  end

  add_index "orders", ["date"], name: "index_orders_on_date", using: :btree
  add_index "orders", ["shop_id", "date", "user_id"], name: "index_orders_on_shop_id_and_date_and_user_id", using: :btree
  add_index "orders", ["shop_id", "source_type", "date"], name: "index_orders_on_shop_id_and_source_type_and_date", where: "(source_type IS NOT NULL)", using: :btree
  add_index "orders", ["shop_id", "status", "status_date"], name: "index_orders_on_shop_id_and_status_and_status_date", using: :btree
  add_index "orders", ["shop_id", "uniqid"], name: "index_orders_on_shop_id_and_uniqid", unique: true, using: :btree
  add_index "orders", ["source_type", "source_id"], name: "index_orders_on_source_type_and_source_id", using: :btree
  add_index "orders", ["uniqid"], name: "index_orders_on_uniqid", using: :btree
  add_index "orders", ["user_id"], name: "index_orders_on_user_id", using: :btree

  create_table "partner_rewards", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "invited_customer_id"
    t.integer  "fee"
    t.integer  "transaction_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "profile_events", force: :cascade do |t|
    t.integer  "user_id",    limit: 8, null: false
    t.integer  "shop_id",              null: false
    t.string   "industry",             null: false
    t.string   "property",             null: false
    t.string   "value",                null: false
    t.integer  "views"
    t.integer  "carts"
    t.integer  "purchases"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "profile_events", ["user_id", "shop_id", "industry", "property"], name: "index_profile_events_all_columns", using: :btree
  add_index "profile_events", ["user_id", "shop_id"], name: "index_profile_events_on_user_id_and_shop_id", using: :btree

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

  create_table "recommender_blocks", force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "name",                       null: false
    t.string   "description"
    t.integer  "limit",       default: 6,    null: false
    t.string   "code",                       null: false
    t.boolean  "active",      default: true, null: false
    t.jsonb    "rules"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "recommender_blocks", ["shop_id", "code"], name: "index_recommender_blocks_on_shop_id_and_code", unique: true, using: :btree

  create_table "recommender_statistics", force: :cascade do |t|
    t.string   "efficiency", limit: 3000
    t.integer  "shop_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "recommender_statistics", ["shop_id"], name: "index_recommender_statistics_on_shop_id", using: :btree

  create_table "reputations", id: :bigserial, force: :cascade do |t|
    t.string   "name"
    t.integer  "rating"
    t.text     "plus"
    t.text     "minus"
    t.text     "comment"
    t.datetime "published_at"
    t.integer  "shop_id"
    t.integer  "entity_id",    limit: 8
    t.string   "entity_type"
    t.integer  "parent_id",    limit: 8
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "status",                 default: 0,  null: false
    t.integer  "client_id",    limit: 8
    t.string   "video_url"
    t.integer  "images",       limit: 8, default: [],              array: true
  end

  add_index "reputations", ["entity_type", "entity_id"], name: "index_reputations_on_entity_type_and_entity_id", using: :btree
  add_index "reputations", ["parent_id"], name: "index_reputations_on_parent_id", using: :btree
  add_index "reputations", ["shop_id"], name: "index_reputations_on_shop_id", using: :btree

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

  create_table "rtb_bid_requests", force: :cascade do |t|
    t.string   "ssp"
    t.string   "ssid"
    t.string   "bid_id"
    t.string   "imp_id"
    t.string   "site_domain"
    t.string   "site_page"
    t.float    "bidfloor"
    t.string   "bidfloorcur"
    t.float    "bid_price"
    t.integer  "rtb_job_id"
    t.boolean  "bid_done"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.boolean  "win"
  end

  add_index "rtb_bid_requests", ["bid_done"], name: "index_rtb_bid_requests_on_bid_done", where: "(bid_done IS TRUE)", using: :btree
  add_index "rtb_bid_requests", ["created_at", "ssp"], name: "index_rtb_bid_requests_on_created_at_and_ssp", where: "(bid_done IS TRUE)", using: :btree
  add_index "rtb_bid_requests", ["ssp"], name: "index_rtb_bid_requests_on_ssp", using: :btree
  add_index "rtb_bid_requests", ["ssp"], name: "index_rtb_bid_requests_on_ssp_conditioned", where: "(bid_done IS TRUE)", using: :btree

  create_table "rtb_clicks", force: :cascade do |t|
    t.string   "url"
    t.string   "user_agent"
    t.string   "ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rtb_impressions", id: :bigserial, force: :cascade do |t|
    t.string   "code"
    t.string   "bid_id",              null: false
    t.string   "ad_id",               null: false
    t.float    "price",               null: false
    t.string   "currency",            null: false
    t.integer  "shop_id",             null: false
    t.integer  "item_id",   limit: 8, null: false
    t.integer  "user_id",   limit: 8, null: false
    t.boolean  "clicked"
    t.boolean  "purchased"
    t.datetime "date"
    t.string   "domain"
    t.string   "page"
    t.string   "banner"
    t.string   "ssp"
  end

  add_index "rtb_impressions", ["code"], name: "index_rtb_impressions_on_code", unique: true, using: :btree

  create_table "rtb_internal_impressions", force: :cascade do |t|
    t.string   "code"
    t.string   "bid_id",              null: false
    t.string   "banner"
    t.float    "price",               null: false
    t.string   "currency",            null: false
    t.integer  "user_id",   limit: 8, null: false
    t.boolean  "clicked"
    t.boolean  "purchased"
    t.datetime "date"
    t.string   "domain"
    t.string   "page"
  end

  create_table "rtb_jobs", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",                                 null: false
    t.integer "user_id",        limit: 8,                null: false
    t.integer "counter",                  default: 0,    null: false
    t.date    "date"
    t.string  "url"
    t.string  "currency"
    t.boolean "active",                   default: true, null: false
    t.string  "logo"
    t.jsonb   "products"
    t.integer "source_user_id", limit: 8
  end

  add_index "rtb_jobs", ["active", "date", "source_user_id"], name: "index_rtb_jobs_on_active_and_date_and_source_user_id", where: "(active IS TRUE)", using: :btree
  add_index "rtb_jobs", ["active", "date", "user_id"], name: "index_rtb_jobs_on_active_and_date_and_user_id", where: "(active IS TRUE)", using: :btree
  add_index "rtb_jobs", ["date", "counter"], name: "index_rtb_jobs_on_date_and_counter", where: "(counter = 0)", using: :btree
  add_index "rtb_jobs", ["shop_id", "date"], name: "index_rtb_jobs_on_shop_id_and_date", using: :btree
  add_index "rtb_jobs", ["shop_id", "source_user_id"], name: "index_rtb_jobs_on_shop_id_and_source_user_id", using: :btree
  add_index "rtb_jobs", ["shop_id", "user_id"], name: "index_rtb_jobs_on_shop_id_and_user_id", using: :btree
  add_index "rtb_jobs", ["shop_id"], name: "index_rtb_jobs_on_shop_id", using: :btree
  add_index "rtb_jobs", ["user_id"], name: "index_rtb_jobs_on_user_id", using: :btree

  create_table "rtb_propellers", force: :cascade do |t|
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "rtb_propellers", ["code"], name: "index_rtb_propellers_on_code", unique: true, using: :btree

  create_table "search_queries", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id",           null: false
    t.integer "user_id", limit: 8, null: false
    t.date    "date",              null: false
    t.string  "query",             null: false
  end

  add_index "search_queries", ["shop_id", "date", "user_id"], name: "index_search_queries_on_shop_id_and_date_and_user_id", using: :btree
  add_index "search_queries", ["shop_id", "query"], name: "index_search_queries_on_shop_id_and_query", using: :btree
  add_index "search_queries", ["user_id"], name: "index_search_queries_on_user_id", using: :btree

  create_table "search_query_redirects", force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "query"
    t.string   "redirect_link"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "search_query_redirects", ["shop_id", "query"], name: "index_search_query_redirects_on_shop_id_and_query", unique: true, using: :btree

  create_table "search_settings", force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "landing_page"
    t.string   "filter_position",           default: "none"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "theme_id",        limit: 8
    t.string   "theme_type"
    t.string   "language",                  default: "english"
    t.string   "search_type",               default: "full",    null: false
  end

  add_index "search_settings", ["shop_id", "theme_id", "theme_type"], name: "index_search_settings_theme", using: :btree
  add_index "search_settings", ["shop_id"], name: "index_search_settings_on_shop_id", unique: true, using: :btree

  create_table "segments", force: :cascade do |t|
    t.integer  "shop_id",                               null: false
    t.string   "name",                                  null: false
    t.integer  "segment_type",          default: 0,     null: false
    t.integer  "client_count",          default: 0,     null: false
    t.integer  "with_email_count",      default: 0,     null: false
    t.integer  "trigger_client_count",  default: 0,     null: false
    t.integer  "digest_client_count",   default: 0,     null: false
    t.integer  "web_push_client_count", default: 0,     null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "deleted",               default: false, null: false
    t.boolean  "updating",              default: false, null: false
    t.jsonb    "filters",               default: {},    null: false
  end

  add_index "segments", ["shop_id"], name: "index_segments_on_shop_id", using: :btree

  create_table "sessions", id: :bigserial, force: :cascade do |t|
    t.integer "user_id",    limit: 8,   null: false
    t.string  "code",       limit: 255, null: false
    t.string  "city",       limit: 255
    t.string  "country",    limit: 255
    t.string  "language",   limit: 255
    t.string  "useragent"
    t.jsonb   "segment"
    t.date    "updated_at"
  end

  add_index "sessions", ["code"], name: "sessions_uniqid_key", unique: true, using: :btree
  add_index "sessions", ["segment"], name: "index_sessions_on_segment", where: "(segment IS NOT NULL)", using: :gin
  add_index "sessions", ["user_id"], name: "index_sessions_on_user_id", using: :btree

  create_table "shop_brands", force: :cascade do |t|
    t.string   "brand"
    t.integer  "popularity", default: 0, null: false
    t.integer  "shop_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "shop_brands", ["shop_id"], name: "index_shop_brands_on_shop_id", using: :btree

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

  create_table "shop_images", force: :cascade do |t|
    t.integer  "shop_id",                null: false
    t.string   "file",                   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "image_type", default: 0, null: false
  end

  add_index "shop_images", ["shop_id", "image_type"], name: "index_shop_images_on_shop_id_and_image_type", using: :btree

  create_table "shop_inventories", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "inventory_type"
    t.boolean  "active"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.float    "min_cpc_price",  default: 1.0,   null: false
    t.integer  "currency_id",                    null: false
    t.string   "name"
    t.integer  "image_width"
    t.integer  "image_height"
    t.jsonb    "settings"
    t.boolean  "archive",        default: false, null: false
    t.integer  "payment_type",   default: 0,     null: false
    t.integer  "timeout"
    t.integer  "item_count"
    t.string   "title"
  end

  add_index "shop_inventories", ["shop_id", "inventory_type"], name: "index_shop_inventories_on_shop_id_and_inventory_type", using: :btree

  create_table "shop_inventory_banners", force: :cascade do |t|
    t.integer  "shop_inventory_id",                null: false
    t.string   "image_file_name",                  null: false
    t.string   "image_content_type",               null: false
    t.integer  "image_file_size",                  null: false
    t.datetime "image_updated_at",                 null: false
    t.string   "url",                              null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.float    "ratio",              default: 1.0, null: false
    t.integer  "position",           default: 1,   null: false
    t.decimal  "min_price",          default: 0.0, null: false
    t.integer  "currency_id"
    t.jsonb    "prices"
  end

  create_table "shop_locations", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                      null: false
    t.string   "external_id",                  null: false
    t.string   "name",                         null: false
    t.string   "external_type"
    t.integer  "parent_id",          limit: 8
    t.string   "parent_external_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "shop_locations", ["shop_id", "external_id"], name: "index_shop_locations_on_shop_id_and_external_id", unique: true, using: :btree

  create_table "shop_metrics", id: :bigserial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "orders",                                  default: 0,   null: false
    t.integer "real_orders",                             default: 0,   null: false
    t.decimal "revenue",                                 default: 0.0, null: false
    t.decimal "real_revenue",                            default: 0.0, null: false
    t.integer "visitors",                                default: 0,   null: false
    t.integer "products_viewed",                         default: 0,   null: false
    t.integer "triggers_enabled_count",                  default: 0,   null: false
    t.integer "triggers_orders",                         default: 0,   null: false
    t.decimal "triggers_revenue",                        default: 0.0, null: false
    t.integer "digests_orders",                          default: 0,   null: false
    t.decimal "digests_revenue",                         default: 0.0, null: false
    t.integer "abandoned_products",                      default: 0,   null: false
    t.decimal "abandoned_money",                         default: 0.0, null: false
    t.date    "date",                                                  null: false
    t.integer "triggers_sent",                           default: 0,   null: false
    t.integer "triggers_clicked",                        default: 0,   null: false
    t.decimal "triggers_revenue_real",                   default: 0.0, null: false
    t.integer "triggers_orders_real",                    default: 0,   null: false
    t.integer "digests_sent",                            default: 0,   null: false
    t.integer "digests_clicked",                         default: 0,   null: false
    t.decimal "digests_revenue_real",                    default: 0.0, null: false
    t.integer "digests_orders_real",                     default: 0,   null: false
    t.integer "subscription_popup_showed",               default: 0
    t.integer "subscription_accepted",                   default: 0
    t.integer "orders_original_count",                   default: 0
    t.decimal "orders_original_revenue",                 default: 0.0
    t.integer "orders_recommended_count",                default: 0
    t.decimal "orders_recommended_revenue",              default: 0.0
    t.integer "product_views_total",                     default: 0
    t.integer "product_views_recommended",               default: 0
    t.jsonb   "top_products",                                                       array: true
    t.jsonb   "products_statistics"
    t.integer "web_push_subscription_popup_showed",      default: 0
    t.integer "web_push_subscription_accepted",          default: 0
    t.integer "web_push_triggers_sent",                  default: 0,   null: false
    t.integer "web_push_triggers_clicked",               default: 0,   null: false
    t.integer "web_push_triggers_orders",                default: 0,   null: false
    t.integer "web_push_triggers_revenue",               default: 0,   null: false
    t.integer "web_push_triggers_orders_real",           default: 0,   null: false
    t.integer "web_push_triggers_revenue_real",          default: 0,   null: false
    t.integer "orders_with_recommender_count",           default: 0,   null: false
    t.integer "web_push_digests_sent",                   default: 0,   null: false
    t.integer "web_push_digests_clicked",                default: 0,   null: false
    t.integer "web_push_digests_orders",                 default: 0,   null: false
    t.integer "web_push_digests_revenue",                default: 0,   null: false
    t.integer "web_push_digests_orders_real",            default: 0,   null: false
    t.integer "web_push_digests_revenue_real",           default: 0,   null: false
    t.integer "remarketing_carts",                       default: 0,   null: false
    t.integer "remarketing_impressions",                 default: 0,   null: false
    t.integer "remarketing_clicks",                      default: 0,   null: false
    t.integer "remarketing_orders",                      default: 0,   null: false
    t.integer "remarketing_revenue",                     default: 0,   null: false
    t.integer "recommendation_requests"
    t.integer "web_push_subscription_permission_showed", default: 0
  end

  add_index "shop_metrics", ["shop_id", "date"], name: "index_shop_metrics_on_shop_id_and_date", unique: true, using: :btree
  add_index "shop_metrics", ["shop_id"], name: "index_shop_metrics_on_shop_id", using: :btree

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

  create_table "shop_themes", id: :bigserial, force: :cascade do |t|
    t.string   "name",                         null: false
    t.integer  "theme_id",                     null: false
    t.integer  "shop_id"
    t.string   "theme_type",                   null: false
    t.jsonb    "variables"
    t.text     "compiled_css"
    t.boolean  "is_custom",    default: false, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "source_type"
  end

  add_index "shop_themes", ["shop_id", "theme_type"], name: "index_shop_themes_on_shop_id_and_theme_type", using: :btree
  add_index "shop_themes", ["shop_id"], name: "index_shop_themes_on_shop_id", using: :btree

  create_table "shopify_shops", force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "token",      null: false
    t.string   "domain",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "shopify_shops", ["shop_id"], name: "index_shopify_shops_on_shop_id", using: :btree

  create_table "shops", id: :bigserial, force: :cascade do |t|
    t.string   "uniqid",                        limit: 255,                 null: false
    t.string   "name",                          limit: 255,                 null: false
    t.boolean  "active",                                    default: true,  null: false
    t.integer  "customer_id"
    t.boolean  "connected",                                 default: false
    t.string   "url",                           limit: 255
    t.boolean  "ab_testing"
    t.datetime "ab_testing_started_at"
    t.datetime "ab_testing_finished_at"
    t.string   "secret",                        limit: 255
    t.integer  "partner_id"
    t.datetime "connected_at"
    t.string   "mean_monthly_orders_count",     limit: 255
    t.integer  "category_id"
    t.integer  "cms_id"
    t.string   "currency",                      limit: 255, default: "₽"
    t.boolean  "requested_ab_testing",                      default: false, null: false
    t.string   "yml_file_url",                  limit: 255
    t.boolean  "yml_loaded",                                default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "strict_recommendations",                    default: false, null: false
    t.boolean  "export_to_ct",                              default: false
    t.integer  "manager_id"
    t.boolean  "enable_nda",                                default: false
    t.boolean  "gives_rewards",                             default: true,  null: false
    t.boolean  "hopeless",                                  default: false, null: false
    t.boolean  "restricted",                                default: false, null: false
    t.datetime "last_valid_yml_file_loaded_at"
    t.text     "connection_status_last_track"
    t.string   "brb_address"
    t.integer  "shard",                                     default: 0,     null: false
    t.datetime "manager_remind_date"
    t.integer  "yml_errors",                                default: 0,     null: false
    t.boolean  "track_order_status",                        default: false, null: false
    t.integer  "trigger_pause",                             default: 1
    t.integer  "yml_load_period",                           default: 24,    null: false
    t.datetime "last_try_to_load_yml_at"
    t.boolean  "supply_available",                          default: false, null: false
    t.boolean  "use_brb",                                   default: false
    t.integer  "scoring",                                   default: 0,     null: false
    t.decimal  "triggers_cpa",                              default: 4.6,   null: false
    t.decimal  "digests_cpa",                               default: 2.0,   null: false
    t.decimal  "triggers_cpa_cap",                          default: 300.0, null: false
    t.decimal  "digests_cpa_cap",                           default: 300.0, null: false
    t.boolean  "remarketing_enabled",                       default: false
    t.decimal  "remarketing_cpa",                           default: 4.6,   null: false
    t.decimal  "remarketing_cpa_cap",                       default: 300.0, null: false
    t.boolean  "match_users_with_dmp",                      default: true
    t.integer  "web_push_balance",                          default: 100,   null: false
    t.datetime "last_orders_sync"
    t.boolean  "have_industry_products",                    default: false, null: false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "plan",                                      default: "l"
    t.boolean  "plan_fixed",                                default: false
    t.string   "currency_code"
    t.integer  "js_sdk"
    t.boolean  "reputations_enabled",                       default: false, null: false
    t.integer  "geo_law"
    t.boolean  "has_products_jewelry",                      default: false
    t.boolean  "has_products_kids",                         default: false
    t.boolean  "has_products_fashion",                      default: false
    t.boolean  "has_products_pets",                         default: false
    t.boolean  "has_products_cosmetic",                     default: false
    t.boolean  "has_products_fmcg",                         default: false
    t.boolean  "has_products_auto",                         default: false
    t.jsonb    "verify_domain",                             default: {},    null: false
    t.datetime "last_orders_import_at"
    t.datetime "yml_load_start_at"
    t.string   "yml_state"
    t.boolean  "mailings_restricted",                       default: false, null: false
    t.boolean  "yml_notification",                          default: true,  null: false
    t.boolean  "dont_disconnect",                           default: false, null: false
    t.boolean  "has_products_realty",                       default: false
    t.boolean  "plan_by_mails"
    t.integer  "plan_by_mails_min",                         default: 0
    t.integer  "plan_by_mails_count",                       default: 0
    t.integer  "plan_by_mails_extra",                       default: 0
    t.boolean  "yml_description",                           default: false, null: false
  end

  add_index "shops", ["cms_id"], name: "index_shops_on_cms_id", using: :btree
  add_index "shops", ["customer_id"], name: "index_shops_on_customer_id", using: :btree
  add_index "shops", ["manager_id"], name: "index_shops_on_manager_id", using: :btree
  add_index "shops", ["uniqid"], name: "shops_uniqid_key", unique: true, using: :btree

  create_table "styles", force: :cascade do |t|
    t.integer  "shop_id",                 null: false
    t.string   "shop_uniqid", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "theme_id",    limit: 8
    t.string   "theme_type"
  end

  add_index "styles", ["shop_id", "theme_id", "theme_type"], name: "index_styles_theme", using: :btree
  add_index "styles", ["shop_id"], name: "index_styles_on_shop_id", unique: true, using: :btree
  add_index "styles", ["shop_uniqid"], name: "index_styles_on_shop_uniqid", unique: true, using: :btree

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

  create_table "subscription_invoices", force: :cascade do |t|
    t.integer  "shop_id"
    t.date     "date"
    t.float    "amount"
    t.integer  "subscription_plan_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "subscription_invoices", ["shop_id"], name: "index_subscription_invoices_on_shop_id", using: :btree
  add_index "subscription_invoices", ["subscription_plan_id"], name: "index_subscription_invoices_on_subscription_plan_id", using: :btree

  create_table "subscription_plans", force: :cascade do |t|
    t.integer  "shop_id"
    t.datetime "paid_till"
    t.decimal  "price"
    t.string   "product"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "active",     default: true
    t.boolean  "renewal",    default: true, null: false
  end

  add_index "subscription_plans", ["shop_id"], name: "index_subscription_plans_on_shop_id", using: :btree

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
    t.string   "button"
    t.text     "agreement"
    t.integer  "popup_type",                       default: 0,     null: false
    t.integer  "timer",                            default: 90,    null: false
    t.boolean  "timer_enabled",                    default: true,  null: false
    t.integer  "pager",                            default: 5,     null: false
    t.boolean  "pager_enabled",                    default: false, null: false
    t.integer  "cursor",                           default: 50,    null: false
    t.boolean  "cursor_enabled",                   default: false, null: false
    t.boolean  "products",                         default: true,  null: false
    t.text     "successfully"
    t.integer  "theme_id",             limit: 8
    t.string   "theme_type"
    t.integer  "segment_id"
  end

  add_index "subscriptions_settings", ["shop_id", "theme_id", "theme_type"], name: "index_subscriptions_settings_theme", using: :btree

  create_table "suggested_queries", force: :cascade do |t|
    t.string   "keyword"
    t.string   "synonym"
    t.float    "score"
    t.integer  "shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "suggested_queries", ["shop_id", "keyword"], name: "index_suggested_queries_on_shop_id_and_keyword", unique: true, using: :btree

  create_table "thematic_collection_sections", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "thematic_collection_id"
    t.text     "rules"
    t.string   "name"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "thematic_collections", force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "name"
    t.text     "keywords"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "theme_purchases", force: :cascade do |t|
    t.integer  "theme_id"
    t.integer  "shop_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "theme_purchases", ["shop_id"], name: "index_theme_purchases_on_shop_id", using: :btree
  add_index "theme_purchases", ["theme_id", "shop_id"], name: "index_theme_purchases_on_theme_id_and_shop_id", unique: true, using: :btree
  add_index "theme_purchases", ["theme_id"], name: "index_theme_purchases_on_theme_id", using: :btree

  create_table "themes", force: :cascade do |t|
    t.string   "name",                       null: false
    t.string   "theme_type",                 null: false
    t.jsonb    "variables"
    t.string   "file",                       null: false
    t.boolean  "free",       default: false, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "themes", ["name", "theme_type"], name: "index_themes_on_name_and_theme_type", unique: true, using: :btree

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
    t.integer  "currency_id",                  default: 1,   null: false
    t.string   "transaction_id"
  end

  create_table "trigger_mail_statistics", force: :cascade do |t|
    t.date     "date",                   null: false
    t.integer  "shop_id",                null: false
    t.integer  "opened",     default: 0, null: false
    t.integer  "clicked",    default: 0, null: false
    t.integer  "bounced",    default: 0, null: false
    t.integer  "sent",       default: 0, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "trigger_mail_statistics", ["date"], name: "index_trigger_mail_statistics_on_date", using: :btree
  add_index "trigger_mail_statistics", ["shop_id", "date"], name: "index_trigger_mail_statistics_on_shop_id_and_date", unique: true, using: :btree
  add_index "trigger_mail_statistics", ["shop_id"], name: "index_trigger_mail_statistics_on_shop_id", using: :btree

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
    t.string   "mailchimp_campaign_id"
    t.datetime "activated_at"
    t.integer  "images_dimension",                        default: 3
    t.integer  "theme_id",                    limit: 8
    t.string   "theme_type"
    t.jsonb    "template_data"
    t.boolean  "simple_editor",                           default: true,  null: false
    t.string   "intro_text"
    t.jsonb    "statistic"
    t.text     "text_template",                           default: "",    null: false
  end

  add_index "trigger_mailings", ["shop_id", "theme_id", "theme_type"], name: "index_trigger_mailings_theme", using: :btree
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
    t.integer  "bounce_reason",      limit: 2
    t.boolean  "unsubscribed"
  end

  add_index "trigger_mails", ["client_id"], name: "index_trigger_mails_on_client_id", using: :btree
  add_index "trigger_mails", ["code"], name: "index_trigger_mails_on_code", unique: true, using: :btree
  add_index "trigger_mails", ["date", "shop_id"], name: "index_trigger_mails_on_date_and_shop_id", using: :btree
  add_index "trigger_mails", ["shop_id", "trigger_mailing_id", "opened"], name: "index_trigger_mails_on_shop_id_and_trigger_mailing_id", using: :btree
  add_index "trigger_mails", ["trigger_mailing_id", "date"], name: "index_trigger_mails_on_trigger_mailing_id", using: :btree

  create_table "user_taxonomies", force: :cascade do |t|
    t.integer "user_id"
    t.date    "date"
    t.string  "taxonomy"
    t.string  "brand"
    t.string  "event"
  end

  add_index "user_taxonomies", ["date"], name: "index_user_taxonomies_on_date", using: :btree
  add_index "user_taxonomies", ["taxonomy"], name: "index_user_taxonomies_on_taxonomy", using: :btree
  add_index "user_taxonomies", ["user_id", "taxonomy", "date", "brand"], name: "index_user_taxonomies_with_brand", using: :btree
  add_index "user_taxonomies", ["user_id", "taxonomy", "date"], name: "index_user_taxonomies_on_user_id_and_taxonomy_and_date", unique: true, using: :btree

  create_table "users", id: :bigserial, force: :cascade do |t|
    t.string  "gender",           limit: 1
    t.jsonb   "fashion_sizes"
    t.boolean "allergy"
    t.jsonb   "cosmetic_hair"
    t.jsonb   "cosmetic_skin"
    t.jsonb   "children"
    t.jsonb   "compatibility"
    t.jsonb   "vds"
    t.jsonb   "pets"
    t.jsonb   "jewelry"
    t.jsonb   "cosmetic_perfume"
  end

  create_table "vendor_campaigns", force: :cascade do |t|
    t.integer  "vendor_id"
    t.integer  "shop_id"
    t.string   "name"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "shop_inventory_id",               null: false
    t.float    "max_cpc_price",                   null: false
    t.integer  "currency_id",                     null: false
    t.datetime "launched_at"
    t.integer  "status",             default: 0
    t.string   "brand"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "url"
    t.string   "categories",                                   array: true
    t.boolean  "all_categories"
    t.integer  "item_count"
    t.jsonb    "filters",            default: {}, null: false
  end

  add_index "vendor_campaigns", ["vendor_id", "shop_id"], name: "index_vendor_campaigns_on_vendor_id_and_shop_id", using: :btree

  create_table "vendor_shops", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "vendor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "vendor_shops", ["vendor_id", "shop_id"], name: "index_vendor_shops_on_vendor_id_and_shop_id", unique: true, using: :btree

  create_table "vendors", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "visits", id: :bigserial, force: :cascade do |t|
    t.date    "date",                          null: false
    t.integer "user_id", limit: 8,             null: false
    t.integer "shop_id",                       null: false
    t.integer "pages",             default: 1, null: false
  end

  add_index "visits", ["date", "user_id", "shop_id"], name: "index_visits_on_date_and_user_id_and_shop_id", unique: true, using: :btree
  add_index "visits", ["shop_id", "date"], name: "index_visits_on_shop_id_and_date", using: :btree
  add_index "visits", ["user_id"], name: "index_visits_on_user_id", using: :btree

  create_table "wear_type_dictionaries", force: :cascade do |t|
    t.string "type_name"
    t.string "word"
  end

  create_table "web_push_digest_batches", id: :bigserial, force: :cascade do |t|
    t.integer "web_push_digest_id", limit: 8,                 null: false
    t.integer "end_id",             limit: 8
    t.boolean "completed",                    default: false, null: false
    t.integer "start_id",           limit: 8
    t.integer "shop_id"
    t.integer "client_ids",         limit: 8,                              array: true
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
    t.boolean  "showed",                             default: false,                null: false
  end

  add_index "web_push_digest_messages", ["client_id"], name: "index_web_push_digest_messages_on_client_id", using: :btree
  add_index "web_push_digest_messages", ["code"], name: "index_web_push_digest_messages_on_code", unique: true, using: :btree
  add_index "web_push_digest_messages", ["date", "shop_id"], name: "index_web_push_digest_messages_on_date_and_shop_id", using: :btree
  add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_digest_id_and_showed", where: "(showed = true)", using: :btree
  add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_digest_id_unsubscribed", where: "(unsubscribed = false)", using: :btree
  add_index "web_push_digest_messages", ["shop_id", "web_push_digest_id"], name: "index_web_push_digest_msg_on_shop_id_and_web_push_trigger_id", where: "(clicked = true)", using: :btree
  add_index "web_push_digest_messages", ["web_push_digest_id", "date"], name: "index_web_push_digest_messages_on_web_push_digest_id", using: :btree

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
    t.jsonb    "actions"
    t.string   "additional_image"
  end

  add_index "web_push_digests", ["shop_id"], name: "index_web_push_digests_on_shop_id", using: :btree

  create_table "web_push_packet_purchases", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "shop_id"
    t.integer  "amount",      null: false
    t.integer  "price",       null: false
    t.integer  "currency_id", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

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
    t.string   "button"
    t.text     "agreement"
    t.boolean  "manual_mode",                          default: false
    t.string   "safari_website_push_id"
    t.string   "certificate_password"
    t.string   "certificate_file_name"
    t.string   "certificate_content_type"
    t.integer  "certificate_file_size"
    t.datetime "certificate_updated_at"
    t.text     "pem_content"
    t.string   "service_worker_path"
    t.text     "successfully"
    t.integer  "popup_type",                           default: 0,     null: false
    t.integer  "timer",                                default: 30,    null: false
    t.boolean  "timer_enabled",                        default: true,  null: false
    t.integer  "pager",                                default: 5,     null: false
    t.boolean  "pager_enabled",                        default: false, null: false
    t.integer  "cursor",                               default: 50,    null: false
    t.boolean  "cursor_enabled",                       default: false, null: false
    t.boolean  "products",                             default: false, null: false
    t.integer  "theme_id",                 limit: 8
    t.string   "theme_type"
    t.string   "subdomain"
  end

  add_index "web_push_subscriptions_settings", ["shop_id", "theme_id", "theme_type"], name: "index_web_push_subscriptions_settings_theme", using: :btree
  add_index "web_push_subscriptions_settings", ["subdomain"], name: "index_web_push_subscriptions_settings_on_subdomain", unique: true, using: :btree

  create_table "web_push_token_errors", id: :bigserial, force: :cascade do |t|
    t.integer  "client_id",  limit: 8
    t.integer  "shop_id"
    t.jsonb    "message"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "web_push_tokens", id: :bigserial, force: :cascade do |t|
    t.integer  "client_id",  limit: 8, null: false
    t.integer  "shop_id",    limit: 8, null: false
    t.jsonb    "token"
    t.string   "browser"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "web_push_tokens", ["client_id", "token"], name: "index_web_push_tokens_on_client_id_and_token", unique: true, using: :btree
  add_index "web_push_tokens", ["client_id"], name: "index_web_push_tokens_on_client_id", using: :btree
  add_index "web_push_tokens", ["shop_id"], name: "index_web_push_tokens_on_shop_id", using: :btree

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
    t.boolean  "showed",                        default: false,                null: false
  end

  add_index "web_push_trigger_messages", ["client_id"], name: "index_web_push_trigger_messages_on_client_id", using: :btree
  add_index "web_push_trigger_messages", ["code"], name: "index_web_push_trigger_messages_on_code", unique: true, using: :btree
  add_index "web_push_trigger_messages", ["date", "shop_id"], name: "index_web_push_trigger_messages_on_date_and_shop_id", using: :btree
  add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], name: "index_web_push_trigger_msg_on_shop_and_trigger_unsubscribed", where: "(unsubscribed = true)", using: :btree
  add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], name: "index_web_push_trigger_msg_on_shop_id_and_trigger_id_and_showed", where: "(showed = true)", using: :btree
  add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], name: "index_web_push_trigger_msg_on_shop_id_and_web_push_trigger_id", where: "(clicked = true)", using: :btree
  add_index "web_push_trigger_messages", ["web_push_trigger_id", "date"], name: "index_web_push_trigger_messages_on_web_push_trigger_id", using: :btree

  create_table "web_push_triggers", id: :bigserial, force: :cascade do |t|
    t.integer  "shop_id",                                  null: false
    t.string   "trigger_type", limit: 255,                 null: false
    t.string   "subject",      limit: 255,                 null: false
    t.boolean  "enabled",                  default: false, null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "message",      limit: 125
    t.jsonb    "statistic"
  end

  create_table "wizard_configurations", force: :cascade do |t|
    t.integer  "shop_id",                           null: false
    t.jsonb    "industrials",       default: []
    t.boolean  "orders_history",    default: false
    t.boolean  "orders_sync",       default: false
    t.jsonb    "triggers",          default: []
    t.jsonb    "web_push_triggers", default: []
    t.boolean  "completed",         default: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "locations",         default: 0
    t.boolean  "subscribers",       default: false
    t.jsonb    "products",          default: []
  end

  add_index "wizard_configurations", ["shop_id"], name: "index_wizard_configurations_on_shop_id", unique: true, using: :btree

end
