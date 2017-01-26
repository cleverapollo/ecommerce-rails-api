class CreateClientCarts < ActiveRecord::Migration
  def change
    create_table :client_carts, id: :bigserial do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :shop_id, null: false
      t.jsonb :items
      t.date :date
    end
    add_index :client_carts, :date # For regular clear
    add_index :client_carts, [:shop_id, :user_id], unique: true

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_client_carts_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('client_carts_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE client_carts ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE client_carts ALTER COLUMN id SET DEFAULT generate_next_client_carts_id();
      ALTER TABLE client_carts ALTER COLUMN id SET NOT NULL;
    SQL
    
  end
end
