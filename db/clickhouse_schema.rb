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

ActiveRecord::Schema.define(version: 0) do

  create_table "actions", id: false, force: :cascade do |t|
    t.integer  "session_id",                                         null: false
    t.string   "current_session_code", limit: 255,                   null: false
    t.integer  "shop_id",                                            null: false
    t.string   "event",                limit: 255,                   null: false
    t.string   "object_type",          limit: 255,                   null: false
    t.string   "object_id",            limit: 255,                   null: false
    t.string   "recommended_by",       limit: 255
    t.string   "recommended_code",     limit: 255
    t.string   "referer",              limit: 255
    t.string   "useragent",            limit: 255,                   null: false
    t.datetime "created_at",                       default: "now()", null: false
    t.date     "date",                             default: "now()", null: false
  end

  create_table "brand_campaign_statistics_events", force: :cascade do |t|
    t.integer  "brand_campaign_statistic_id",                         null: false
    t.integer  "brand_campaign_shop_id",                              null: false
    t.string   "recommender",                 limit: 255,             null: false
    t.string   "event",                       limit: 255,             null: false
    t.integer  "recommended",                             default: 0, null: false
    t.datetime "created_at",                                          null: false
    t.date     "date",                                                null: false
  end

  create_table "interactions", force: :cascade do |t|
    t.integer  "shop_id",                      null: false
    t.integer  "user_id",                      null: false
    t.integer  "item_id",                      null: false
    t.string   "code",             limit: 255, null: false
    t.string   "recommender_code", limit: 255, null: false
    t.datetime "created_at",                   null: false
    t.date     "date",                         null: false
    t.string   "shard",            limit: 255, null: false
  end

  create_table "order_items", id: false, force: :cascade do |t|
    t.integer  "session_id",                                   null: false
    t.integer  "shop_id",                                      null: false
    t.integer  "amount",                                       null: false
    t.float    "price",                                        null: false
    t.string   "recommended_by", limit: 255
    t.string   "brand",          limit: 255
    t.datetime "created_at",                 default: "now()", null: false
    t.date     "date",                       default: "now()", null: false
  end

  create_table "rtb_bid_requests", force: :cascade do |t|
    t.string   "ssp",         limit: 255,             null: false
    t.string   "ssid",        limit: 255,             null: false
    t.string   "bid_id",      limit: 255,             null: false
    t.string   "imp_id",      limit: 255,             null: false
    t.string   "site_domain", limit: 255,             null: false
    t.string   "site_page",   limit: 255,             null: false
    t.float    "bidfloor",                            null: false
    t.string   "bidfloorcur", limit: 255,             null: false
    t.float    "bid_price",                           null: false
    t.integer  "rtb_job_id",                          null: false
    t.integer  "bid_done",                default: 0, null: false
    t.integer  "win",                     default: 0, null: false
    t.datetime "created_at",                          null: false
    t.date     "date",                                null: false
  end

end
