class MoveInteractions < ActiveRecord::Migration
  def change

  create_table 'interactions', id: :bigint, force: :cascade do |t|
    t.integer  'shop_id',                    null: false
    t.integer  'user_id',          limit: 8, null: false
    t.integer  'item_id',          limit: 8, null: false
    t.integer  'code',                       null: false
    t.integer  'recommender_code'
    t.datetime 'created_at',                 null: false
  end

  add_index 'interactions', ['shop_id', 'created_at', 'recommender_code'], name: 'interactions_shop_id_created_at_recommender_code_idx', where: '(code = 1)', using: :btree
  add_index 'interactions', ['shop_id', 'item_id'], name: 'tmpidx_interactions_1', using: :btree
  add_index 'interactions', ['user_id'], name: 'index_interactions_on_user_id', using: :btree

  execute <<-SQL

    CREATE OR REPLACE FUNCTION generate_next_interaction_id(OUT result bigint) AS $$
      DECLARE
      our_epoch bigint := 1314220021721;
      seq_id bigint;
      now_millis bigint;
      shard_id int := #{SHARD_ID};
      BEGIN
        SELECT nextval('interactions_id_seq')::BIGINT % 1024 INTO seq_id;
        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
        result := (now_millis - our_epoch) << 23;
        result := result | (shard_id << 10);
        result := result | (seq_id);
        END;
        $$ LANGUAGE PLPGSQL;


    ALTER TABLE interactions ALTER COLUMN id TYPE BIGINT;
    ALTER TABLE interactions ALTER COLUMN id SET DEFAULT generate_next_beacon_message_id();
    ALTER TABLE interactions ALTER COLUMN id SET NOT NULL;

  SQL

  end
end
