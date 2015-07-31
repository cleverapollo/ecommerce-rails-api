class CreateClientErrors < ActiveRecord::Migration
  def change

    create_table 'client_errors', id: :bigserial, force: :cascade do |t|
      t.integer  'shop_id'
      t.string   'exception_class',   limit: 255,                 null: false
      t.string   'exception_message', limit: 255,                 null: false
      t.text     'params',                                        null: false
      t.boolean  'resolved',                      default: false, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string   'referer',           limit: 255
    end

    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_client_error_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('client_errors_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE client_errors ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE client_errors ALTER COLUMN id SET DEFAULT generate_next_client_error_id();
      ALTER TABLE client_errors ALTER COLUMN id SET NOT NULL;

    SQL
    
  end
end
