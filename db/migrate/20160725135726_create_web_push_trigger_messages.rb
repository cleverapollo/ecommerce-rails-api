class CreateWebPushTriggerMessages < ActiveRecord::Migration
  def change
    create_table :web_push_trigger_messages, id: :bigserial do |t|
      t.integer  "shop_id",                                                     null: false
      t.text     "trigger_data",                                                null: false
      t.uuid     "code",                         default: "uuid_generate_v4()"
      t.boolean  "clicked",                      default: false,                null: false
      t.integer  "web_push_trigger_id",          limit: 8,                                null: false
      t.boolean  "unsubscribed",                 default: false,                null: false
      t.integer  "client_id",                     limit: 8,                                null: false
      t.date     "date"
      t.timestamps null: false
    end

    add_index "web_push_trigger_messages", ["code"], unique: true
    add_index "web_push_trigger_messages", ["date", "shop_id"]
    add_index "web_push_trigger_messages", ["date"]
    add_index "web_push_trigger_messages", ["shop_id", "web_push_trigger_id"], where: "(clicked is true)", name: w
    add_index "web_push_trigger_messages", ["web_push_trigger_id"]


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_web_push_trigger_messages_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('web_push_trigger_messages_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE web_push_trigger_messages ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE web_push_trigger_messages ALTER COLUMN id SET DEFAULT generate_next_web_push_trigger_messages_id();
      ALTER TABLE web_push_trigger_messages ALTER COLUMN id SET NOT NULL;
    SQL
    
    
  end
end
