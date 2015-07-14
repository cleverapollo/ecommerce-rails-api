class MoveOrders < ActiveRecord::Migration
  def change

    create_table 'orders', id: :bigserial, force: :cascade do |t|
      t.integer  'shop_id',                                         null: false
      t.integer  'user_id',           limit: 8,                     null: false
      t.string   'uniqid',            limit: 255,                   null: false
      t.datetime 'date',                          default: 'now()', null: false
      t.decimal  'value',                         default: 0.0,     null: false
      t.boolean  'recommended',                   default: false,   null: false
      t.integer  'ab_testing_group'
      t.decimal  'recommended_value',             default: 0.0,     null: false
      t.decimal  'common_value',                  default: 0.0,     null: false
      t.integer  'source_id'
      t.string   'source_type'
      t.integer  'status',                        default: 0,       null: false
      t.date     'status_date'
    end

    add_index 'orders', ['date'], name: 'index_orders_on_date', using: :btree
    add_index 'orders', ['shop_id', 'status', 'status_date'], name: 'index_orders_on_shop_id_and_status_and_status_date', using: :btree

    create_table 'order_items', id: :bigserial, force: :cascade do |t|
      t.integer 'order_id',       limit: 8,               null: false
      t.integer 'item_id',        limit: 8,               null: false
      t.integer 'action_id',      limit: 8,               null: false
      t.integer 'amount',                     default: 1, null: false
      t.string  'recommended_by', limit: 255
    end

    add_index 'order_items', ['item_id'], name: 'index_order_items_on_item_id', using: :btree


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_order_id(OUT result bigint) AS $$
        DECLARE
        our_epoch bigint := 1314220021721;
        seq_id bigint;
        now_millis bigint;
        shard_id int := #{SHARD_ID};
        BEGIN
          SELECT nextval('orders_id_seq')::BIGINT % 1024 INTO seq_id;
          SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
          result := (now_millis - our_epoch) << 23;
          result := result | (shard_id << 10);
          result := result | (seq_id);
          END;
          $$ LANGUAGE PLPGSQL;

      ALTER TABLE orders ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE orders ALTER COLUMN id SET DEFAULT generate_next_order_id();
      ALTER TABLE orders ALTER COLUMN id SET NOT NULL;
    SQL


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_order_item_id(OUT result bigint) AS $$
        DECLARE
        our_epoch bigint := 1314220021721;
        seq_id bigint;
        now_millis bigint;
        shard_id int := #{SHARD_ID};
        BEGIN
          SELECT nextval('order_items_id_seq')::BIGINT % 1024 INTO seq_id;
          SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
          result := (now_millis - our_epoch) << 23;
          result := result | (shard_id << 10);
          result := result | (seq_id);
          END;
          $$ LANGUAGE PLPGSQL;

      ALTER TABLE order_items ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE order_items ALTER COLUMN id SET DEFAULT generate_next_order_item_id();
      ALTER TABLE order_items ALTER COLUMN id SET NOT NULL;
    SQL

  end
end
