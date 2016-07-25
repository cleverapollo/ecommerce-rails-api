class CreateWebPushDigests < ActiveRecord::Migration
  def change
    create_table :web_push_digests do |t|
      t.integer  "shop_id",                                                    null: false
      t.string   "name",                        limit: 255,                    null: false
      t.string   "subject",                     limit: 255,                    null: false
      t.string   "state",                       limit: 255, default: "draft",  null: false
      t.integer  "total_mails_count"
      t.datetime "started_at"
      t.datetime "finished_at"
      t.timestamps null: false
    end

    add_index :web_push_digests, :shop_id

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_web_push_digests_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('web_push_digests_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE web_push_digests ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE web_push_digests ALTER COLUMN id SET DEFAULT generate_next_web_push_digests_id();
      ALTER TABLE web_push_digests ALTER COLUMN id SET NOT NULL;
    SQL
    
  end
end
