class LinkRtbTablesToShard < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE FOREIGN TABLE sessions_master (
        "id" int8 NOT NULL DEFAULT nextval('sessions_id_seq'::regclass),
        "user_id" int8 NOT NULL,
        "code" varchar(255) NOT NULL COLLATE "default",
        "city" varchar(255) COLLATE "default",
        "country" varchar(255) COLLATE "default",
        "language" varchar(255) COLLATE "default",
        "synced_with_amber_at" date,
        "synced_with_dca_at" date,
        "synced_with_aidata_at" date,
        "synced_with_auditorius_at" date,
        "synced_with_mailru_at" date,
        "synced_with_relapio_at" date,
        "synced_with_republer_at" date,
        "synced_with_advmaker_at" date,
        "useragent" varchar COLLATE "default",
        "segment" jsonb,
        "updated_at" date,
        "synced_with_doubleclick_at" date,
        "synced_with_doubleclick_cart_at" date
      ) SERVER master_server OPTIONS (table_name 'sessions');
      ALTER TABLE sessions_master INHERIT sessions;
      SELECT setval('sessions_id_seq', COALESCE((SELECT MAX(id) FROM sessions) + 1000, 1), false);
      ALTER TABLE sessions_master ADD CONSTRAINT master_check CHECK ( id < #{Session.maximum(:id) || 1} )
    SQL





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

    execute <<-SQL
      CREATE FOREIGN TABLE rtb_bid_requests_master (
      	"id" int4 NOT NULL DEFAULT nextval('rtb_bid_requests_id_seq'::regclass),
      	"ssp" varchar COLLATE "default",
      	"ssid" varchar COLLATE "default",
      	"bid_id" varchar COLLATE "default",
      	"imp_id" varchar COLLATE "default",
      	"site_domain" varchar COLLATE "default",
      	"site_page" varchar COLLATE "default",
      	"bidfloor" float8,
      	"bidfloorcur" varchar COLLATE "default",
      	"bid_price" float8,
      	"rtb_job_id" int4,
      	"bid_done" bool,
      	"created_at" timestamp NOT NULL,
      	"updated_at" timestamp NOT NULL,
      	"win" bool
      ) SERVER master_server OPTIONS (table_name 'rtb_bid_requests');
      ALTER TABLE rtb_bid_requests_master INHERIT rtb_bid_requests;
      SELECT setval('rtb_bid_requests_id_seq', COALESCE((SELECT MAX(id) FROM rtb_bid_requests) + 1000, 1), false);
      ALTER TABLE rtb_bid_requests_master ADD CONSTRAINT master_check CHECK ( id < #{RtbBidRequest.maximum(:id) || 1} )
    SQL




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

    execute <<-SQL
      CREATE FOREIGN TABLE rtb_impressions_master (
        "id" int8 NOT NULL DEFAULT nextval('rtb_impressions_id_seq'::regclass),
        "code" varchar COLLATE "default",
        "bid_id" varchar NOT NULL COLLATE "default",
        "ad_id" varchar NOT NULL COLLATE "default",
        "price" float8 NOT NULL,
        "currency" varchar NOT NULL COLLATE "default",
        "shop_id" int4 NOT NULL,
        "item_id" int8 NOT NULL,
        "user_id" int8 NOT NULL,
        "clicked" bool,
        "purchased" bool,
        "date" timestamp NULL,
        "domain" varchar COLLATE "default",
        "page" varchar COLLATE "default",
        "banner" varchar COLLATE "default",
        "ssp" varchar COLLATE "default"
      ) SERVER master_server OPTIONS (table_name 'rtb_impressions');
      ALTER TABLE rtb_impressions_master INHERIT rtb_impressions;
      SELECT setval('rtb_impressions_id_seq', COALESCE((SELECT MAX(id) FROM rtb_impressions) + 1000, 1), false);
      ALTER TABLE rtb_impressions_master ADD CONSTRAINT master_check CHECK ( id < #{RtbImpression.maximum(:id) || 1} )
    SQL



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

    execute <<-SQL
      CREATE FOREIGN TABLE rtb_internal_impressions_master (
        "id" int4 NOT NULL DEFAULT nextval('rtb_internal_impressions_id_seq'::regclass),
        "code" varchar COLLATE "default",
        "bid_id" varchar NOT NULL COLLATE "default",
        "banner" varchar COLLATE "default",
        "price" float8 NOT NULL,
        "currency" varchar NOT NULL COLLATE "default",
        "user_id" int8 NOT NULL,
        "clicked" bool,
        "purchased" bool,
        "date" timestamp NULL,
        "domain" varchar COLLATE "default",
        "page" varchar COLLATE "default"
      ) SERVER master_server OPTIONS (table_name 'rtb_internal_impressions');
      ALTER TABLE rtb_internal_impressions_master INHERIT rtb_internal_impressions;
      SELECT setval('rtb_internal_impressions_id_seq', COALESCE((SELECT MAX(id) FROM rtb_internal_impressions) + 1000, 1), false);
      ALTER TABLE rtb_internal_impressions_master ADD CONSTRAINT master_check CHECK ( id < #{RtbInternalImpression.maximum(:id) || 1} )
    SQL




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

    execute <<-SQL
      CREATE FOREIGN TABLE rtb_jobs_master (
        "id" int8 NOT NULL DEFAULT nextval('rtb_jobs_id_seq'::regclass),
        "shop_id" int4 NOT NULL,
        "user_id" int8 NOT NULL,
        "item_id" int8 NOT NULL,
        "counter" int4 NOT NULL DEFAULT 0,
        "date" date,
        "image" varchar COLLATE "default",
        "price" float8,
        "url" varchar COLLATE "default",
        "currency" varchar COLLATE "default",
        "name" varchar COLLATE "default",
        "active" bool NOT NULL DEFAULT true,
        "logo" varchar COLLATE "default",
        "products" jsonb
      ) SERVER master_server OPTIONS (table_name 'rtb_jobs');
      ALTER TABLE rtb_jobs_master INHERIT rtb_jobs;
      SELECT setval('rtb_jobs_id_seq', COALESCE((SELECT MAX(id) FROM rtb_jobs) + 1000, 1), false);
      ALTER TABLE rtb_jobs_master ADD CONSTRAINT master_check CHECK ( id < #{RtbJob.maximum(:id) || 1} )
    SQL
  end

  def down
    execute 'DROP FOREIGN TABLE sessions_master CASCADE;'
    execute 'DROP FOREIGN TABLE rtb_bid_requests_master CASCADE;'
    drop_table :rtb_bid_requests

    execute 'DROP FOREIGN TABLE rtb_impressions_master CASCADE;'
    drop_table :rtb_impressions

    execute 'DROP FOREIGN TABLE rtb_internal_impressions_master CASCADE;'
    drop_table :rtb_internal_impressions

    execute 'DROP FOREIGN TABLE rtb_jobs_master CASCADE;'
    drop_table :rtb_jobs
  end
end
