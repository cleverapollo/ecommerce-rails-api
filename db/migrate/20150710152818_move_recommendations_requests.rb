class MoveRecommendationsRequests < ActiveRecord::Migration
  def change
    create_table 'recommendations_requests', id: :bigserial, force: :cascade do |t|
      t.integer  'shop_id',                 null: false
      t.integer  'category_id',             null: false
      t.string   'recommender_type',        limit: 255,           null: false
      t.boolean  'clicked',                 default: false,       null: false
      t.integer  'recommendations_count',   null: false
      t.text     'recommended_ids',         default: [],          null: false, array: true
      t.decimal  'duration',                null: false
      t.integer  'user_id',                  limit: 8
      t.string   'session_code',            limit: 255
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_recommendations_request_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('recommendations_requests_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE recommendations_requests ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE recommendations_requests ALTER COLUMN id SET DEFAULT generate_next_beacon_message_id();
      ALTER TABLE recommendations_requests ALTER COLUMN id SET NOT NULL;

    SQL
  end
end
