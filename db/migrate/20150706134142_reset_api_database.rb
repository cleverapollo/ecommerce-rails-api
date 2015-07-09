class ResetApiDatabase < ActiveRecord::Migration
  def change

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


    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_item_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('items_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;

      CREATE OR REPLACE FUNCTION generate_next_action_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('actions_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;

      ALTER TABLE items ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE items ALTER COLUMN id SET DEFAULT generate_next_item_id();
      ALTER TABLE items ALTER COLUMN id SET NOT NULL;
      ALTER TABLE actions ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE actions ALTER COLUMN id SET DEFAULT generate_next_action_id();
      ALTER TABLE actions ALTER COLUMN id SET NOT NULL;

    SQL

  end
end
