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

ActiveRecord::Schema.define(version: 20150729145844) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "btree_gin"
  enable_extension "uuid-ossp"

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
    t.integer  "item_category_id", limit: 8
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "advertiser_item_categories", ["advertiser_id"], name: "index_advertiser_item_categories_on_advertiser_id", using: :btree
  add_index "advertiser_item_categories", ["item_category_id"], name: "index_advertiser_item_categories_on_item_category_id", using: :btree

  create_table "advertiser_purchases", force: :cascade do |t|
    t.integer  "advertiser_id"
    t.integer  "item_id",        limit: 8
    t.integer  "shop_id"
    t.integer  "order_id",       limit: 8
    t.float    "price"
    t.string   "recommended_by"
    t.date     "date"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
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


  create_table "beacon_offers", force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "uuid",                         null: false
    t.string   "major",                        null: false
    t.string   "image_url",                    null: false
    t.string   "title",                        null: false
    t.string   "notification",                 null: false
    t.boolean  "enabled",      default: false, null: false
    t.text     "description",                  null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end


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

  create_table "ipn_messages", force: :cascade do |t|
    t.text     "content",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mahout_actions", force: :cascade do |t|
    t.integer "user_id",    limit: 8
    t.integer "item_id",    limit: 8
    t.integer "shop_id",    limit: 8
    t.integer "timestamp"
    t.float   "preference"
  end

  add_index "mahout_actions", ["shop_id"], name: "index_mahout_actions_on_shop_id", using: :btree
  add_index "mahout_actions", ["user_id", "item_id"], name: "index_mahout_actions_on_user_id_and_item_id", unique: true, using: :btree

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
    t.integer  "user_id",    limit: 8, null: false
    t.integer  "shop_id",              null: false
    t.jsonb    "value",                null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "profile_attributes", ["user_id"], name: "index_profile_attributes_on_user_id", using: :btree

  create_table "promotions", force: :cascade do |t|
    t.string   "brand",        null: false
    t.string   "categories",   null: false, array: true
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.date     "finishing_at"
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
    t.integer  "version_rank",                                  null: false
    t.integer  "installed_rank",                                null: false
    t.string   "version",        limit: 50,                     null: false
    t.string   "description",    limit: 200,                    null: false
    t.string   "type",           limit: 20,                     null: false
    t.string   "script",         limit: 1000,                   null: false
    t.integer  "checksum"
    t.string   "installed_by",   limit: 100,                    null: false
    t.datetime "installed_on",                default: "now()", null: false
    t.integer  "execution_time",                                null: false
    t.boolean  "success",                                       null: false
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
  add_index "sessions", ["user_id"], name: "index_sessions_on_user_id", using: :btree

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
    t.boolean  "restricted",                                                        default: false, null: false
    t.decimal  "revenue_per_visit",                                                 default: 0.0,   null: false
    t.datetime "last_valid_yml_file_loaded_at"
    t.text     "connection_status_last_track"
    t.integer  "plan_value"
    t.boolean  "dont_disconnect",                                                   default: false, null: false
    t.string   "brb_address"
    t.integer  "shard",                                                             default: 0,     null: false
    t.datetime "manager_remind_date"
    t.integer  "yml_errors",                                                        default: 0,     null: false
    t.integer  "trigger_pause",                                                     default: 14
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

  create_table "url_aliases", force: :cascade do |t|
    t.string   "pattern",    limit: 255, null: false
    t.string   "alias",      limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :bigserial, force: :cascade do |t|
    t.jsonb "gender",   default: {"f"=>50, "m"=>50}, null: false
    t.jsonb "size",     default: {},                 null: false
    t.jsonb "children", default: [],                 null: false
  end

  create_table "wear_type_dictionaries", force: :cascade do |t|
    t.string "word"
    t.string "type_name"
  end


  create_table "brands", force: :cascade do |t|
    t.string   "name"
    t.string   "keyword"
    t.text     "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "media", force: :cascade do |t|
    t.string   "uniqid",                                                                  null: false
    t.string   "name",                                                                    null: false
    t.string   "url",                 limit: 255
    t.integer  "customer_id"
    t.boolean  "restricted",                                              default: false, null: false
    t.string   "secret",              limit: 255
    t.decimal  "efficiency",                      precision: 5, scale: 2, default: 0.0,   null: false
    t.integer  "manager_id"
    t.integer  "shard",                                                   default: 0,     null: false
    t.datetime "manager_remind_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
