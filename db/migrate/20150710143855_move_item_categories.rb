class MoveItemCategories < ActiveRecord::Migration
  def change
  create_table 'item_categories', id: :bigint, force: :cascade do |t|
    t.integer  'shop_id',            null: false
    t.integer  'parent_id'
    t.string   'external_id',        null: false
    t.string   'parent_external_id'
    t.string   'name'
    t.datetime 'created_at',         null: false
    t.datetime 'updated_at',         null: false
  end

  add_index 'item_categories', ['shop_id', 'external_id'], name: 'index_item_categories_on_shop_id_and_external_id', unique: true, using: :btree

  execute <<-SQL

    CREATE OR REPLACE FUNCTION generate_next_item_categorie_id(OUT result bigint) AS $$
      DECLARE
      our_epoch bigint := 1314220021721;
      seq_id bigint;
      now_millis bigint;
      shard_id int := #{SHARD_ID};
      BEGIN
        SELECT nextval('item_categories_id_seq')::BIGINT % 1024 INTO seq_id;
        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
        result := (now_millis - our_epoch) << 23;
        result := result | (shard_id << 10);
        result := result | (seq_id);
        END;
        $$ LANGUAGE PLPGSQL;

    ALTER TABLE item_categories ALTER COLUMN id TYPE BIGINT;
    ALTER TABLE item_categories ALTER COLUMN id SET DEFAULT generate_next_item_categorie_id();
    ALTER TABLE item_categories ALTER COLUMN id SET NOT NULL;

    SQL
  end
end
