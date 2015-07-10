class CreateClients < ActiveRecord::Migration
  def change
    create_table "clients", id: :bigint, force: :cascade do |t|
      t.integer  "shop_id",                                                              null: false
      t.integer  "user_id",                   limit: 8,                   null: false
      t.boolean  "bought_something",                      default: false,                null: false
      t.integer  "ab_testing_group"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "external_id",               limit: 255
      t.string   "email",                     limit: 255
      t.boolean  "digests_enabled",                       default: true,                 null: false
      t.uuid     "code",                                  default: "uuid_generate_v4()"
      t.boolean  "subscription_popup_showed",             default: false,                null: false
      t.boolean  "triggers_enabled",                      default: true,                 null: false
      t.datetime "last_trigger_mail_sent_at"
      t.boolean  "accepted_subscription",                 default: false,                null: false
      t.string   "location"
    end

    add_index "clients", ["accepted_subscription", "shop_id"], name: "index_clients_on_accepted_subscription_and_shop_id", where: "(subscription_popup_showed = true)", using: :btree
    add_index "clients", ["code"], name: "index_clients_on_code", unique: true, using: :btree
    add_index "clients", ["digests_enabled", "shop_id"], name: "index_clients_on_digests_enabled_and_shop_id", using: :btree
    add_index "clients", ["email"], name: "index_clients_on_email", using: :btree
    add_index "clients", ["shop_id", "id"], name: "shops_users_shop_id_id_idx", where: "((email IS NOT NULL) AND (digests_enabled = true))", using: :btree

    execute <<-SQL
      CREATE INDEX idx_clients_shop_id_last_trigger_email_nulls_first ON clients (shop_id, last_trigger_mail_sent_at ASC NULLS FIRST) where triggers_enabled = 't' and email is not null;
    SQL


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_clients_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('clients_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;

      ALTER TABLE clients ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE clients ALTER COLUMN id SET DEFAULT generate_next_clients_id();
      ALTER TABLE clients ALTER COLUMN id SET NOT NULL;
    SQL
  end
end
