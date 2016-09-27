class CreateWebPushTokens < ActiveRecord::Migration
  def up
    create_table :web_push_tokens, id: :bigserial do |t|
      t.integer :client_id, limit: 8, index: true, null: false
      t.integer :shop_id, limit: 8, index: true, null: false
      t.jsonb :token
      t.string :browser

      t.timestamps null: false
    end
    add_index :web_push_tokens, [:client_id, :token], unique: true

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_web_push_tokens_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('web_push_tokens_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE web_push_tokens ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE web_push_tokens ALTER COLUMN id SET DEFAULT generate_next_web_push_tokens_id();
      ALTER TABLE web_push_tokens ALTER COLUMN id SET NOT NULL;
    SQL

    # merge tokens to the new table
    Client.where('web_push_enabled is true').all.each do |client|
      client.append_web_push_token(eval(client.web_push_token).to_json) if client.web_push_token.present?
    end

    # remove old column
    remove_columns :clients, :web_push_token, :web_push_browser
  end

  def down
    drop_table :web_push_tokens
    execute <<-SQL
      DROP FUNCTION IF EXISTS generate_next_web_push_tokens_id(OUT result bigint);
    SQL

    add_column :clients, :web_push_token, :string
    add_column :clients, :web_push_browser, :string
  end
end
