class CreateFunctionUniqIdForVisits < ActiveRecord::Migration
  def change
    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_visits_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('visits_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE visits ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE visits ALTER COLUMN id SET DEFAULT generate_next_visits_id();
      ALTER TABLE visits ALTER COLUMN id SET NOT NULL;
    SQL
  end
end
