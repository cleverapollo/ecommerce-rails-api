class MoveSubscriptionsSettings < ActiveRecord::Migration
  def change
    create_table "subscriptions_settings", id: :bigserial, force: :cascade do |t|
      t.integer  "shop_id",                                null: false
      t.boolean  "enabled",              default: false,   null: false
      t.boolean  "overlay",              default: true,    null: false
      t.text     "header",                                 null: false
      t.text     "text",                                   null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "picture_file_name",    limit: 255
      t.string   "picture_content_type", limit: 255
      t.integer  "picture_file_size"
      t.datetime "picture_updated_at"
    end

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_subscriptions_setting_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('subscriptions_settings_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE subscriptions_settings ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE subscriptions_settings ALTER COLUMN id SET DEFAULT generate_next_subscriptions_setting_id();
      ALTER TABLE subscriptions_settings ALTER COLUMN id SET NOT NULL;
    SQL
  end
end


