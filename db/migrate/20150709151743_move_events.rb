class MoveEvents < ActiveRecord::Migration
  def change

    create_table 'events', id: :bigint, force: :cascade do |t|
      t.integer  'shop_id',                                     null: false
      t.string   'name',            limit: 255,                 null: false
      t.text     'additional_info'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.boolean  'processed',                   default: false, null: false
    end

    add_index 'events', ['created_at'], name: 'index_events_on_created_at', using: :btree
    add_index 'events', ['name'], name: 'index_events_on_name', using: :btree
    add_index 'events', ['shop_id'], name: 'index_events_on_shop_id', using: :btree

    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_event_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('events_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE events ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE events ALTER COLUMN id SET DEFAULT generate_next_event_id();
      ALTER TABLE events ALTER COLUMN id SET NOT NULL;

    SQL

  end
end
