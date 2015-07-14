class CreateBeaconMessages < ActiveRecord::Migration
  def change

    create_table 'beacon_messages', id: :bigserial, force: :cascade do |t|
      t.integer  'shop_id'
      t.integer  'user_id',     limit: 8
      t.integer  'session_id',  limit: 8
      t.text     'params',                                 null: false
      t.boolean  'notified',               default: false, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string   'deal_id',    limit: 255
      t.boolean  'tracked',                default: false, null: false
    end

    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_beacon_message_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('beacon_messages_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE beacon_messages ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE beacon_messages ALTER COLUMN id SET DEFAULT generate_next_beacon_message_id();
      ALTER TABLE beacon_messages ALTER COLUMN id SET NOT NULL;

    SQL

  end
end
