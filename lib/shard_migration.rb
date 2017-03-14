class ShardMigration < ActiveRecord::Migration

  def create_table(table_name)
    super(table_name, id: :bigserial) do |td|
      yield td if block_given?
    end
    
    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_#{table_name}_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('#{table_name}_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE #{table_name} ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE #{table_name} ALTER COLUMN id SET DEFAULT generate_next_#{table_name}_id();
      ALTER TABLE #{table_name} ALTER COLUMN id SET NOT NULL;
    SQL
  end

  def drop_table(table_name, options = {})
    super(table_name)
    execute "DROP FUNCTION IF EXISTS generate_next_#{table_name}_id(OUT result bigint);"
  end
end