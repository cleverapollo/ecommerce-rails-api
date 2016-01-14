class SearchQuery < ActiveRecord::Migration
  def change
    create_table :search_queries, id: :bigserial do |t|
      t.integer :shop_id, null: false
      t.integer :user_id, limit: 8, null: false
      t.date :date, null: false
      t.string :query, null: false
    end
    add_index :search_queries, [:shop_id, :query]


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_search_query_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('search_queries_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;

      ALTER TABLE search_queries ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE search_queries ALTER COLUMN id SET DEFAULT generate_next_search_query_id();
      ALTER TABLE search_queries ALTER COLUMN id SET NOT NULL;
    SQL

  end
end
