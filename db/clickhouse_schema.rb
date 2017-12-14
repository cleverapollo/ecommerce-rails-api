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

  # TABLE: .inner.events_connected
  # SQL: CREATE MATERIALIZED VIEW rees46.events_connected ( date Date,  shop_id UInt32,  event String,  created_at AggregateFunction(max, DateTime)) ENGINE = AggregatingMergeTree(date, (shop_id, event, date), 8192) AS SELECT date, shop_id, event, maxState(created_at) AS created_at FROM rees46.actions  GROUP BY date, shop_id, event
  create_table "events_connected", id: false, force: :cascade do |t|
    t.date     "date",                   null: false
    t.integer  "shop_id",                null: false
    t.string   "event",      limit: 255, null: false
    t.datetime "created_at", limit: 0,   null: false
  end

  # TABLE: actions
  # SQL: CREATE TABLE rees46.actions ( session_id UInt64,  current_session_code String,  shop_id UInt32,  event String,  object_type String,  object_id String,  recommended_by Nullable(String),  recommended_code Nullable(String),  price Float32 DEFAULT CAST(0 AS Float32),  brand Nullable(String),  referer Nullable(String),  useragent String,  created_at DateTime DEFAULT now(),  date Date DEFAULT CAST(now() AS Date)) ENGINE = ReplicatedMergeTree('/clickhouse/tables/actions/actions', 'server_rtb', date, (session_id, shop_id, event, object_type, object_id, date), 8192)
  create_table "actions", id: false, force: :cascade do |t|
    t.integer  "session_id",           limit: 8,                     null: false
    t.string   "current_session_code", limit: 255,                   null: false
    t.integer  "shop_id",                                            null: false
    t.string   "event",                limit: 255,                   null: false
    t.string   "object_type",          limit: 255,                   null: false
    t.string   "object_id",            limit: 255,                   null: false
    t.string   "recommended_by",       limit: 255
    t.string   "recommended_code",     limit: 255
    t.float    "price",                            default: 0.0,     null: false
    t.string   "brand",                limit: 255
    t.string   "referer",              limit: 255
    t.string   "useragent",            limit: 255,                   null: false
    t.datetime "created_at",                       default: "now()", null: false
    t.date     "date",                             default: "now()", null: false
  end

  # TABLE: brand_campaign_statistics_events
  # SQL: CREATE TABLE rees46.brand_campaign_statistics_events ( id UInt64,  brand_campaign_statistic_id UInt64,  brand_campaign_shop_id UInt64,  recommender String,  event String,  recommended UInt8 DEFAULT 0,  created_at DateTime,  date Date) ENGINE = MergeTree(date, (brand_campaign_shop_id, brand_campaign_statistic_id, date), 8192)
  create_table "brand_campaign_statistics_events", force: :cascade do |t|
    t.integer  "brand_campaign_statistic_id", limit: 8,               null: false
    t.integer  "brand_campaign_shop_id",      limit: 8,               null: false
    t.string   "recommender",                 limit: 255,             null: false
    t.string   "event",                       limit: 255,             null: false
    t.integer  "recommended",                             default: 0, null: false
    t.datetime "created_at",                                          null: false
    t.date     "date",                                                null: false
  end

  # TABLE: events_connected
  # SQL: CREATE MATERIALIZED VIEW rees46.events_connected ( date Date,  shop_id UInt32,  event String,  created_at AggregateFunction(max, DateTime)) ENGINE = AggregatingMergeTree(date, (shop_id, event, date), 8192) AS SELECT date, shop_id, event, maxState(created_at) AS created_at FROM rees46.actions  GROUP BY date, shop_id, event
  create_table "events_connected", id: false, force: :cascade do |t|
    t.date     "date",                   null: false
    t.integer  "shop_id",                null: false
    t.string   "event",      limit: 255, null: false
    t.datetime "created_at", limit: 0,   null: false
  end

  # TABLE: interactions
  # SQL: CREATE TABLE rees46.interactions ( id UInt64,  shop_id UInt32,  user_id UInt64,  item_id UInt64,  code String,  recommender_code String,  created_at DateTime,  date Date,  shard String) ENGINE = MergeTree(date, (shop_id, user_id, item_id, date, shard), 8192)
  create_table "interactions", force: :cascade do |t|
    t.integer  "shop_id",                      null: false
    t.integer  "user_id",          limit: 8,   null: false
    t.integer  "item_id",          limit: 8,   null: false
    t.string   "code",             limit: 255, null: false
    t.string   "recommender_code", limit: 255, null: false
    t.datetime "created_at",                   null: false
    t.date     "date",                         null: false
    t.string   "shard",            limit: 255, null: false
  end

  # TABLE: order_items
  # SQL: CREATE TABLE rees46.order_items ( session_id UInt64,  shop_id UInt32,  user_id UInt64,  order_id UInt64,  item_uniqid String,  amount UInt32,  price Float32,  recommended_by Nullable(String),  recommended_code Nullable(String),  brand Nullable(String),  created_at DateTime DEFAULT now(),  date Date DEFAULT CAST(now() AS Date)) ENGINE = MergeTree(date, (session_id, shop_id, date), 8192)
  create_table "order_items", id: false, force: :cascade do |t|
    t.integer  "session_id",       limit: 8,                     null: false
    t.integer  "shop_id",                                        null: false
    t.integer  "user_id",          limit: 8,                     null: false
    t.integer  "order_id",         limit: 8,                     null: false
    t.string   "item_uniqid",      limit: 255,                   null: false
    t.integer  "amount",                                         null: false
    t.float    "price",                                          null: false
    t.string   "recommended_by",   limit: 255
    t.string   "recommended_code", limit: 255
    t.string   "brand",            limit: 255
    t.datetime "created_at",                   default: "now()", null: false
    t.date     "date",                         default: "now()", null: false
  end

  # TABLE: profile_events
  # SQL: CREATE TABLE rees46.profile_events ( session_id UInt64,  current_session_code String,  shop_id UInt32,  event String,  industry String,  property String,  value String,  created_at DateTime DEFAULT now(),  date Date DEFAULT CAST(now() AS Date)) ENGINE = MergeTree(date, (session_id, shop_id, event, industry, property, date), 8192)
  create_table "profile_events", id: false, force: :cascade do |t|
    t.integer  "session_id",           limit: 8,                     null: false
    t.string   "current_session_code", limit: 255,                   null: false
    t.integer  "shop_id",                                            null: false
    t.string   "event",                limit: 255,                   null: false
    t.string   "industry",             limit: 255,                   null: false
    t.string   "property",             limit: 255,                   null: false
    t.string   "value",                limit: 255,                   null: false
    t.datetime "created_at",                       default: "now()", null: false
    t.date     "date",                             default: "now()", null: false
  end

  # TABLE: recone_actions
  # SQL: CREATE TABLE rees46.recone_actions ( session_id UInt64,  current_session_code String,  shop_id UInt32,  event String,  item_id Nullable(String),  object_type String,  object_id String,  object_price Float32 DEFAULT CAST(0 AS Float32),  recommended_by Nullable(String),  price Float32 DEFAULT CAST(0 AS Float32),  amount UInt32 DEFAULT CAST(1 AS UInt32),  brand Nullable(String),  referer Nullable(String),  created_at DateTime DEFAULT now(),  date Date DEFAULT CAST(now() AS Date)) ENGINE = MergeTree(date, (session_id, shop_id, event, object_type, object_id, date), 8192)
  create_table "recone_actions", id: false, force: :cascade do |t|
    t.integer  "session_id",           limit: 8,                     null: false
    t.string   "current_session_code", limit: 255,                   null: false
    t.integer  "shop_id",                                            null: false
    t.string   "event",                limit: 255,                   null: false
    t.string   "item_id",              limit: 255
    t.string   "object_type",          limit: 255,                   null: false
    t.string   "object_id",            limit: 255,                   null: false
    t.float    "object_price",                     default: 0.0,     null: false
    t.string   "recommended_by",       limit: 255
    t.float    "price",                            default: 0.0,     null: false
    t.integer  "amount",                           default: 0,       null: false
    t.string   "brand",                limit: 255
    t.string   "referer",              limit: 255
    t.datetime "created_at",                       default: "now()", null: false
    t.date     "date",                             default: "now()", null: false
  end

  # TABLE: rtb_bid_requests
  # SQL: CREATE TABLE rees46.rtb_bid_requests ( id UInt64,  ssp String,  ssid String,  bid_id String,  imp_id String,  site_domain String,  site_page String,  bidfloor Float32,  bidfloorcur String,  bid_price Float32,  rtb_job_id UInt32,  bid_done UInt8 DEFAULT 0,  win UInt8 DEFAULT 0,  created_at DateTime,  date Date) ENGINE = MergeTree(date, (bid_done, win, created_at, date, rtb_job_id), 8192)
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

  # TABLE: visits
  # SQL: CREATE TABLE rees46.visits ( session_id UInt64,  current_session_code String,  user_id UInt64,  shop_id UInt32,  url String,  useragent String,  ip String,  country Nullable(String),  city Nullable(String),  latitude Nullable(String),  longitude Nullable(String),  created_at DateTime DEFAULT now(),  date Date DEFAULT CAST(now() AS Date)) ENGINE = MergeTree(date, (session_id, shop_id, user_id, date), 8192)
  create_table "visits", id: false, force: :cascade do |t|
    t.integer  "session_id",           limit: 8,                     null: false
    t.string   "current_session_code", limit: 255,                   null: false
    t.integer  "user_id",              limit: 8,                     null: false
    t.integer  "shop_id",                                            null: false
    t.string   "url",                  limit: 255,                   null: false
    t.string   "useragent",            limit: 255,                   null: false
    t.string   "ip",                   limit: 255,                   null: false
    t.string   "country",              limit: 255
    t.string   "city",                 limit: 255
    t.string   "latitude",             limit: 255
    t.string   "longitude",            limit: 255
    t.datetime "created_at",                       default: "now()", null: false
    t.date     "date",                             default: "now()", null: false
  end

  # TABLE: profile_events
  # SQL: CREATE TABLE rees46.profile_events ( session_id UInt64,  current_session_code String,  shop_id UInt32,  event String,  industry String,  property String,  value String,  created_at DateTime DEFAULT now(),  date Date DEFAULT CAST(now() AS Date)) ENGINE = MergeTree(date, (session_id, shop_id, event, industry, property, date), 8192)
  create_table "profile_events", id: false, force: :cascade do |t|
    t.integer  "session_id",           limit: 8,                     null: false
    t.string   "current_session_code", limit: 255,                   null: false
    t.integer  "shop_id",                                            null: false
    t.string   "event",                limit: 255,                   null: false
    t.string   "industry",             limit: 255,                   null: false
    t.string   "property",             limit: 255,                   null: false
    t.string   "value",                limit: 255,                   null: false
    t.datetime "created_at",                       default: "now()", null: false
    t.date     "date",                             default: "now()", null: false
  end
end
