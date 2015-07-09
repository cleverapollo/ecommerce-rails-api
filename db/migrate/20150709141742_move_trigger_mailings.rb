class MoveTriggerMailings < ActiveRecord::Migration
  def change

    create_table 'mailings_settings', id: :bigint, force: :cascade do |t|
      t.integer  'shop_id',                       null: false
      t.string   'send_from',         limit: 255, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string   'logo_file_name',    limit: 255
      t.string   'logo_content_type', limit: 255
      t.integer  'logo_file_size'
      t.datetime 'logo_updated_at'
    end

    create_table 'trigger_mailings', id: :bigint, force: :cascade do |t|
      t.integer  'shop_id',                                   null: false
      t.string   'trigger_type',  limit: 255,                 null: false
      t.string   'subject',       limit: 255,                 null: false
      t.text     'template',                                  null: false
      t.text     'item_template',                             null: false
      t.boolean  'enabled',                   default: false, null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end

    add_index 'trigger_mailings', ['shop_id', 'trigger_type'], name: 'index_trigger_mailings_on_shop_id_and_trigger_type', unique: true, using: :btree

    create_table 'trigger_mails', id: :bigint, force: :cascade do |t|
      t.integer  'shop_id',                                           null: false
      t.text     'trigger_data',                                      null: false
      t.uuid     'code',               default: 'uuid_generate_v4()'
      t.boolean  'clicked',            default: false,                null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.boolean  'opened',             default: false,                null: false
      t.integer  'trigger_mailing_id', limit: 8,                      null: false
      t.boolean  'bounced',            default: false,                null: false
      t.integer  'client_id',          limit: 8,                      null: false
    end

    add_index 'trigger_mails', ['code'], name: 'index_trigger_mails_on_code', unique: true, using: :btree
    add_index 'trigger_mails', ['trigger_mailing_id'], name: 'index_trigger_mails_on_trigger_mailing_id', using: :btree



    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_mailings_setting_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('mailings_settings_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE mailings_settings ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE mailings_settings ALTER COLUMN id SET DEFAULT generate_next_mailings_setting_id();
      ALTER TABLE mailings_settings ALTER COLUMN id SET NOT NULL;

    SQL


    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_trigger_mailing_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('trigger_mailings_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE trigger_mailings ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE trigger_mailings ALTER COLUMN id SET DEFAULT generate_next_trigger_mailing_id();
      ALTER TABLE trigger_mailings ALTER COLUMN id SET NOT NULL;

    SQL


    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_trigger_mail_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('trigger_mails_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE trigger_mails ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE trigger_mails ALTER COLUMN id SET DEFAULT generate_next_trigger_mail_id();
      ALTER TABLE trigger_mails ALTER COLUMN id SET NOT NULL;

    SQL


    
  end
end
