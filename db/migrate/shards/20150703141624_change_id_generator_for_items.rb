class ChangeIdGeneratorForItems < ActiveRecord::Migration
  def change

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_item_id(OUT result bigint) AS $$
      DECLARE
      our_epoch bigint := 1314220021721;
      seq_id bigint;
      now_millis bigint;
      shard_id int := 5;
      BEGIN
        SELECT nextval('items_id_seq')::BIGINT % 1024 INTO seq_id;
        SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
        result := (now_millis - our_epoch) << 23;
        result := result | (shard_id << 10);
        result := result | (seq_id);
        END;
        $$ LANGUAGE PLPGSQL;
    SQL

    execute <<-SQL
      ALTER TABLE items ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE items ALTER COLUMN id SET DEFAULT generate_next_item_id();
      ALTER TABLE items ALTER COLUMN id SET NOT NULL;
    SQL

    # execute <<-SQL
    #   CREATE OR REPLACE SEQUENCE items_id_seq
    #     INCREMENT 1
    #     MINVALUE 1
    #     MAXVALUE 9223372036854775807
    #     START 10000000
    #     CACHE 1;
    # SQL

  end
end
