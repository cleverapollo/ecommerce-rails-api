class CreateWebPushDigestBatches < ActiveRecord::Migration
  def change
    create_table "web_push_digest_batches", id: :bigserial, force: :cascade do |t|
      t.integer "web_push_digest_id", limit: 8,                   null: false
      t.integer "end_id",            limit: 8
      t.boolean "completed",                     default: false, null: false
      t.integer "start_id",          limit: 8
      t.integer "shop_id"
    end

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_web_push_digest_batches_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('web_push_digest_batches_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE web_push_digest_batches ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE web_push_digest_batches ALTER COLUMN id SET DEFAULT generate_next_web_push_digest_batches_id();
      ALTER TABLE web_push_digest_batches ALTER COLUMN id SET NOT NULL;
    SQL

    add_index "web_push_digest_batches", ["web_push_digest_id"]
    add_index "web_push_digest_batches", ["shop_id"]
    
  end
end
