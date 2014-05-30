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

ActiveRecord::Schema.define(version: 20140529094135) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "actions", force: true do |t|
    t.integer  "user_id",          limit: 8,                                             null: false
    t.integer  "item_id",          limit: 8,                                             null: false
    t.integer  "view_count",                 default: 0,                                 null: false
    t.datetime "view_date"
    t.integer  "cart_count",                 default: 0,                                 null: false
    t.datetime "cart_date"
    t.integer  "purchase_count",             default: 0,                                 null: false
    t.datetime "purchase_date"
    t.float    "rating",                     default: 0.0
    t.integer  "shop_id",          limit: 8,                                             null: false
    t.integer  "timestamp",                  default: "date_part('epoch'::text, now())", null: false
    t.string   "recommended_by"
    t.integer  "last_action",      limit: 2, default: 1,                                 null: false
    t.integer  "rate_count",                 default: 0,                                 null: false
    t.datetime "rate_date"
    t.integer  "last_user_rating"
    t.boolean  "is_available",               default: true,                              null: false
    t.decimal  "price"
    t.string   "category_uniqid"
    t.string   "locations",                  default: [],                                             array: true
    t.string   "brand"
    t.boolean  "repeatable",                 default: false,                             null: false
  end

  add_index "actions", ["item_id"], name: "index_actions_on_item_id", using: :btree
  add_index "actions", ["shop_id", "is_available", "purchase_count", "timestamp", "category_uniqid"], name: "tmpidx2", using: :btree
  add_index "actions", ["shop_id", "is_available", "timestamp", "category_uniqid"], name: "actions_shop_id_is_available_timestamp_category_uniqid_idx", using: :btree
  add_index "actions", ["shop_id"], name: "index_actions_on_shop_id", using: :btree
  add_index "actions", ["user_id", "item_id", "rating"], name: "index_actions_on_user_id_and_item_id_and_rating", unique: true, using: :btree
  add_index "actions", ["user_id"], name: "index_actions_on_user_id", using: :btree

  create_table "actions_bool", id: false, force: true do |t|
    t.integer "id",                  null: false
    t.integer "user_id",   limit: 8
    t.integer "item_id",   limit: 8
    t.integer "shop_id",   limit: 8
    t.integer "timestamp"
  end

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "customers", force: true do |t|
    t.string   "email",                  default: "",   null: false
    t.string   "encrypted_password",     default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "role",                   default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "phone"
    t.string   "city"
    t.string   "company"
    t.boolean  "subscribed",             default: true, null: false
    t.string   "unsubscribe_token"
    t.integer  "partner_id"
  end

  add_index "customers", ["email"], name: "index_customers_on_email", unique: true, using: :btree
  add_index "customers", ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true, using: :btree

  create_table "insales_shops", force: true do |t|
    t.string   "token"
    t.string   "insales_shop"
    t.string   "insales_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "shop_id"
  end

  add_index "insales_shops", ["shop_id"], name: "index_insales_shops_on_shop_id", using: :btree

  create_table "items", force: true do |t|
    t.integer "shop_id",         limit: 8,                 null: false
    t.string  "uniqid",                                    null: false
    t.decimal "price"
    t.string  "category_uniqid"
    t.boolean "is_available",              default: true,  null: false
    t.string  "locations",                 default: [],                 array: true
    t.string  "name"
    t.text    "description"
    t.string  "url"
    t.string  "image_url"
    t.string  "tags",                      default: [],                 array: true
    t.boolean "widgetable",                default: false, null: false
    t.string  "brand"
    t.boolean "repeatable",                default: false, null: false
  end

  add_index "items", ["uniqid", "shop_id"], name: "items_uniqid_shop_id_key", unique: true, using: :btree

  create_table "mahout_actions", force: true do |t|
    t.integer "user_id",   limit: 8
    t.integer "item_id",   limit: 8
    t.integer "shop_id",   limit: 8
    t.integer "timestamp"
  end

  add_index "mahout_actions", ["shop_id"], name: "index_mahout_actions_on_shop_id", using: :btree
  add_index "mahout_actions", ["user_id", "item_id"], name: "index_mahout_actions_on_user_id_and_item_id", unique: true, using: :btree

  create_table "mailer_jobs", force: true do |t|
    t.string   "state",      default: "enqueued", null: false
    t.integer  "shop_id",                         null: false
    t.text     "statistics"
    t.text     "params",                          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mailing_batches", force: true do |t|
    t.integer  "mailing_id",                      null: false
    t.text     "users",                           null: false
    t.string   "state",      default: "enqueued", null: false
    t.text     "statistics",                      null: false
    t.text     "failed",                          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mailing_batches", ["mailing_id"], name: "index_mailing_batches_on_mailing_id", using: :btree

  create_table "mailings", force: true do |t|
    t.integer  "shop_id",           null: false
    t.string   "token",             null: false
    t.text     "delivery_settings", null: false
    t.text     "items",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mailings", ["token"], name: "index_mailings_on_token", unique: true, using: :btree

  create_table "order_items", force: true do |t|
    t.integer "order_id",       limit: 8,             null: false
    t.integer "item_id",        limit: 8,             null: false
    t.integer "action_id",      limit: 8,             null: false
    t.integer "amount",                   default: 1, null: false
    t.string  "recommended_by"
  end

  create_table "orders", force: true do |t|
    t.integer  "shop_id",                            null: false
    t.integer  "user_id",                            null: false
    t.string   "uniqid",                             null: false
    t.datetime "date",             default: "now()", null: false
    t.integer  "items",            default: [],      null: false, array: true
    t.integer  "amounts",          default: [],      null: false, array: true
    t.decimal  "value",            default: 0.0,     null: false
    t.boolean  "recommended",      default: false,   null: false
    t.integer  "ab_testing_group"
  end

  add_index "orders", ["date"], name: "index_orders_on_date", using: :btree
  add_index "orders", ["shop_id", "uniqid"], name: "index_orders_on_shop_id_and_uniqid", unique: true, using: :btree

  create_table "partners", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "name"
    t.string   "phone"
    t.string   "city"
    t.string   "company"
    t.integer  "role",                   default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "token",                               null: false
  end

  add_index "partners", ["email"], name: "index_partners_on_email", unique: true, using: :btree
  add_index "partners", ["reset_password_token"], name: "index_partners_on_reset_password_token", unique: true, using: :btree

  create_table "potential_customers", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.text     "comment"
    t.boolean  "subscribe",  default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "schema_version", id: false, force: true do |t|
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

  create_table "sessions", force: true do |t|
    t.integer "user_id",   limit: 8,                null: false
    t.string  "uniqid",                             null: false
    t.boolean "is_active",           default: true
    t.string  "useragent"
    t.string  "city"
    t.string  "country"
    t.string  "language"
  end

  add_index "sessions", ["uniqid"], name: "sessions_uniqid_key", unique: true, using: :btree
  add_index "sessions", ["user_id"], name: "index_sessions_on_user_id", using: :btree

  create_table "shop_days_statistics", force: true do |t|
    t.integer "shop_id"
    t.decimal "natural"
    t.decimal "recommended"
    t.date    "date"
    t.integer "natural_count",     default: 0
    t.integer "recommended_count", default: 0
    t.text    "orders_info"
  end

  add_index "shop_days_statistics", ["shop_id"], name: "index_shop_days_statistics_on_shop_id", using: :btree

  create_table "shop_statistics", force: true do |t|
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

  create_table "shops", force: true do |t|
    t.string   "uniqid",                                 null: false
    t.string   "name",                                   null: false
    t.boolean  "active",                 default: true
    t.integer  "customer_id"
    t.datetime "pay_before"
    t.boolean  "pay_notification",       default: false
    t.boolean  "connected",              default: false
    t.string   "url"
    t.string   "branch"
    t.boolean  "ab_testing"
    t.datetime "ab_testing_started_at"
    t.datetime "ab_testing_finished_at"
    t.text     "connection_status"
    t.string   "secret"
    t.integer  "partner_id"
  end

  add_index "shops", ["customer_id"], name: "index_shops_on_customer_id", using: :btree
  add_index "shops", ["uniqid"], name: "shops_uniqid_key", unique: true, using: :btree

  create_table "shops_users", id: false, force: true do |t|
    t.integer  "shop_id",                          null: false
    t.integer  "user_id",                          null: false
    t.boolean  "bought_something", default: false, null: false
    t.integer  "ab_testing_group"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shops_users", ["shop_id", "user_id"], name: "index_shops_users_on_shop_id_and_user_id", unique: true, using: :btree

  create_table "user_shop_relations", force: true do |t|
    t.integer "user_id", limit: 8, null: false
    t.integer "shop_id", limit: 8, null: false
    t.string  "uniqid"
    t.string  "email"
  end

  add_index "user_shop_relations", ["uniqid", "shop_id"], name: "user_shop_relations_uniqid_shop_id_key", unique: true, using: :btree

  create_table "users", force: true do |t|
  end

end
