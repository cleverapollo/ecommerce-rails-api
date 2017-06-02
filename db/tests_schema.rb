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

ActiveRecord::Schema.define(version: 20170602091247) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
  end

  add_index "advertisers", ["email"], name: "index_advertisers_on_email", unique: true, using: :btree
  add_index "advertisers", ["reset_password_token"], name: "index_advertisers_on_reset_password_token", unique: true, using: :btree

  create_table "advertising_platform_purchases", force: :cascade do |t|
    t.integer  "advertising_platform_id"
    t.integer  "shop_id"
    t.integer  "order_id"
    t.float    "price"
    t.date     "date"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "status",                  default: 0, null: false
    t.date     "status_date"
  end

  create_table "advertising_platform_shops", force: :cascade do |t|
    t.integer  "advertising_platform_id"
    t.integer  "shop_id"
    t.date     "last_event_at"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "min_price",               default: 0,    null: false
    t.boolean  "active",                  default: true, null: false
  end

  create_table "advertising_platform_statistics", force: :cascade do |t|
    t.integer  "advertising_platform_id"
    t.integer  "views",                   default: 0,   null: false
    t.integer  "purchases",               default: 0,   null: false
    t.float    "cost",                    default: 0.0, null: false
    t.date     "date",                                  null: false
    t.integer  "clicks",                  default: 0,   null: false
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "advertising_platform_statistics_events", force: :cascade do |t|
    t.integer  "advertising_platform_shop_id"
    t.string   "event",                             null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "advertising_platform_statistic_id"
  end

  create_table "advertising_platform_transactions", force: :cascade do |t|
    t.integer  "advertising_platform_id"
    t.integer  "advertising_platform_shop_id"
    t.integer  "amount"
    t.integer  "transaction_type"
    t.integer  "status"
    t.text     "comment"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "advertising_platforms", force: :cascade do |t|
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
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "balance",                default: 0,   null: false
    t.decimal  "ctr",                    default: 0.0, null: false
    t.decimal  "btr",                    default: 0.0, null: false
    t.decimal  "commission",             default: 0.0, null: false
  end

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

  create_table "currencies", force: :cascade do |t|
    t.string   "code",                          null: false
    t.string   "symbol",                        null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "min_payment",   default: 500,   null: false
    t.float    "exchange_rate", default: 1.0,   null: false
    t.boolean  "payable",       default: false
    t.boolean  "stripe_paid",   default: false, null: false
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
    t.string   "language",                           default: "ru",     null: false
    t.boolean  "notify_about_finances",              default: true,     null: false
    t.integer  "partner_balance",                    default: 0,        null: false
    t.integer  "my_partner_visits",                  default: 0
    t.integer  "my_partner_signups",                 default: 0
    t.string   "api_key",                limit: 255
    t.string   "api_secret",             limit: 255
    t.string   "quick_sign_in_token"
    t.datetime "confirmed_at"
    t.string   "time_zone",                          default: "Moscow", null: false
    t.string   "stripe_customer_id"
    t.string   "stripe_card_last4"
    t.string   "stripe_card_id"
    t.string   "country_code"
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

  create_table "dummy", id: false, force: :cascade do |t|
    t.integer "id",            limit: 8
    t.string  "gender",        limit: 1
    t.jsonb   "fashion_sizes"
    t.boolean "allergy"
    t.jsonb   "cosmetic_hair"
    t.jsonb   "cosmetic_skin"
    t.jsonb   "children",                array: true
    t.jsonb   "compatibility"
    t.jsonb   "vds"
    t.jsonb   "pets"
    t.jsonb   "jewelry"
  end

  create_table "e_komi_requests", force: :cascade do |t|
    t.integer  "shop_id"
    t.string   "country"
    t.string   "city"
    t.string   "postal_code"
    t.string   "address"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "confirmed",   default: false
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

  create_table "partner_rewards", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "invited_customer_id"
    t.integer  "fee"
    t.integer  "transaction_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

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

  add_index "profile_events", ["user_id", "industry", "property"], name: "index_profile_events_on_user_id_and_industry_and_property", using: :btree
  add_index "profile_events", ["user_id", "shop_id", "industry", "property"], name: "index_profile_events_all_columns", using: :btree
  add_index "profile_events", ["user_id", "shop_id", "industry"], name: "index_profile_events_on_user_id_and_shop_id_and_industry", using: :btree
  add_index "profile_events", ["user_id", "shop_id"], name: "index_profile_events_on_user_id_and_shop_id", using: :btree
  add_index "profile_events", ["user_id"], name: "index_profile_events_on_user_id", using: :btree

  create_table "prospects", force: :cascade do |t|
    t.string "filename"
    t.string "domain"
    t.string "location_on_site"
    t.string "company"
    t.string "vertical"
    t.string "quantcast"
    t.string "alexa"
    t.string "telephones"
    t.string "emails"
    t.string "twitter"
    t.string "facebook"
    t.string "linkedIn"
    t.string "google"
    t.string "pinterest"
    t.string "github"
    t.string "instagram"
    t.string "vk"
    t.string "vimeo"
    t.string "youtube"
    t.string "people"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.string "first_detected"
    t.string "last_found"
    t.string "first_indexed"
    t.string "last_indexed"
    t.string "first_name"
    t.string "last_name"
    t.string "name"
    t.string "position"
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
    t.integer "shop_id",                           null: false
    t.integer "user_id",  limit: 8,                null: false
    t.integer "item_id",  limit: 8,                null: false
    t.integer "counter",            default: 0,    null: false
    t.date    "date"
    t.string  "image"
    t.float   "price"
    t.string  "url"
    t.string  "currency"
    t.string  "name"
    t.boolean "active",             default: true, null: false
    t.string  "logo"
    t.jsonb   "products"
  end

  add_index "rtb_jobs", ["active", "date", "user_id"], name: "index_rtb_jobs_on_active_and_date_and_user_id", where: "(active IS TRUE)", using: :btree
  add_index "rtb_jobs", ["date", "counter"], name: "index_rtb_jobs_on_date_and_counter", where: "(counter = 0)", using: :btree
  add_index "rtb_jobs", ["shop_id", "date"], name: "index_rtb_jobs_on_shop_id_and_date", using: :btree
  add_index "rtb_jobs", ["shop_id", "user_id", "item_id"], name: "index_rtb_jobs_on_shop_id_and_user_id_and_item_id", unique: true, using: :btree
  add_index "rtb_jobs", ["shop_id", "user_id"], name: "index_rtb_jobs_on_shop_id_and_user_id", using: :btree
  add_index "rtb_jobs", ["shop_id"], name: "index_rtb_jobs_on_shop_id", using: :btree
  add_index "rtb_jobs", ["user_id"], name: "index_rtb_jobs_on_user_id", using: :btree

  create_table "saas_requests", force: :cascade do |t|
    t.string   "name"
    t.string   "url"
    t.string   "contact"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.integer "user_id",                    limit: 8,   null: false
    t.string  "code",                       limit: 255, null: false
    t.string  "city",                       limit: 255
    t.string  "country",                    limit: 255
    t.string  "language",                   limit: 255
    t.date    "synced_with_amber_at"
    t.date    "synced_with_dca_at"
    t.date    "synced_with_aidata_at"
    t.date    "synced_with_auditorius_at"
    t.date    "synced_with_mailru_at"
    t.date    "synced_with_relapio_at"
    t.date    "synced_with_republer_at"
    t.date    "synced_with_advmaker_at"
    t.string  "useragent"
    t.jsonb   "segment"
    t.date    "updated_at"
    t.date    "synced_with_doubleclick_at"
  end

  add_index "sessions", ["code"], name: "sessions_uniqid_key", unique: true, using: :btree
  add_index "sessions", ["segment"], name: "index_sessions_on_segment", where: "(segment IS NOT NULL)", using: :gin
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

  create_table "shop_images", force: :cascade do |t|
    t.integer  "shop_id",    null: false
    t.string   "file",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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
    t.boolean  "available_ibeacon",                         default: false
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
    t.boolean  "merchandising_enabled",                     default: true,  null: false
    t.integer  "scoring",                                   default: 0,     null: false
    t.decimal  "triggers_cpa",                              default: 4.6,   null: false
    t.decimal  "digests_cpa",                               default: 2.0,   null: false
    t.decimal  "triggers_cpa_cap",                          default: 300.0, null: false
    t.decimal  "digests_cpa_cap",                           default: 300.0, null: false
    t.boolean  "remarketing_enabled",                       default: false
    t.decimal  "remarketing_cpa",                           default: 4.6,   null: false
    t.decimal  "remarketing_cpa_cap",                       default: 300.0, null: false
    t.boolean  "ekomi_enabled"
    t.string   "ekomi_id"
    t.string   "ekomi_key"
    t.boolean  "match_users_with_dmp",                      default: true
    t.integer  "web_push_balance",                          default: 100,   null: false
    t.datetime "last_orders_sync"
    t.boolean  "have_industry_products",                    default: false, null: false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "plan",                                      default: "s"
    t.boolean  "plan_fixed",                                default: false
    t.boolean  "debug_order",                               default: false, null: false
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
  end

  add_index "shops", ["cms_id"], name: "index_shops_on_cms_id", using: :btree
  add_index "shops", ["customer_id"], name: "index_shops_on_customer_id", using: :btree
  add_index "shops", ["manager_id"], name: "index_shops_on_manager_id", using: :btree
  add_index "shops", ["merchandising_enabled"], name: "index_shops_on_merchandising_enabled", where: "(merchandising_enabled IS TRUE)", using: :btree
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
    t.string  "gender",        limit: 1
    t.jsonb   "fashion_sizes"
    t.boolean "allergy"
    t.jsonb   "cosmetic_hair"
    t.jsonb   "cosmetic_skin"
    t.jsonb   "children"
    t.jsonb   "compatibility"
    t.jsonb   "vds"
    t.jsonb   "pets"
    t.jsonb   "jewelry"
  end

  create_table "wear_type_dictionaries", force: :cascade do |t|
    t.string "type_name"
    t.string "word"
  end

  create_table "web_push_packet_purchases", force: :cascade do |t|
    t.integer  "customer_id"
    t.integer  "shop_id"
    t.integer  "amount",      null: false
    t.integer  "price",       null: false
    t.integer  "currency_id", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
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
    t.jsonb    "products",          default: []
    t.boolean  "subscribers",       default: false
  end

  add_index "wizard_configurations", ["shop_id"], name: "index_wizard_configurations_on_shop_id", unique: true, using: :btree

end
