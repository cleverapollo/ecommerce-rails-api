class MoveMailings < ActiveRecord::Migration
  def change

    create_table 'digest_mailing_batches', id: :bigint, force: :cascade do |t|
      t.integer 'digest_mailing_id', limit: 8,                             null: false
      t.integer 'end_id', limit: 8
      t.boolean 'completed',                     default: false, null: false
      t.integer 'start_id', limit: 8
      t.string  'test_email',        limit: 255
    end
    add_index 'digest_mailing_batches', ['digest_mailing_id'], name: 'index_digest_mailing_batches_on_digest_mailing_id', using: :btree

    create_table 'digest_mailing_settings', id: :bigint, force: :cascade do |t|
      t.integer 'shop_id',                   null: false
      t.boolean 'on',      default: false,   null: false
      t.string  'sender',  limit: 255,       null: false
    end
    add_index 'digest_mailing_settings', ['shop_id'], name: 'index_digest_mailing_settings_on_shop_id', using: :btree

    create_table 'digest_mailings', id: :bigint, force: :cascade do |t|
      t.integer  'shop_id',                                          null: false
      t.string   'name',              limit: 255,                    null: false
      t.string   'subject',           limit: 255,                    null: false
      t.text     'template',                                         null: false
      t.string   'items',             limit: 255
      t.string   'state',             limit: 255, default: 'draft',  null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.text     'item_template',                                    null: false
      t.integer  'total_mails_count'
      t.datetime 'started_at'
      t.datetime 'finished_at'
      t.text     'header'
      t.text     'text'
      t.string   'edit_mode',         limit: 255, default: 'simple', null: false
    end
    add_index 'digest_mailings', ['shop_id'], name: 'index_digest_mailings_on_shop_id', using: :btree

    create_table 'digest_mails', id: :bigint, force: :cascade do |t|
      t.integer  'shop_id',                                                null: false
      t.integer  'digest_mailing_id',       limit: 8,                      null: false
      t.integer  'digest_mailing_batch_id', limit: 8,                      null: false
      t.uuid     'code',                    default: 'uuid_generate_v4()'
      t.boolean  'clicked',                 default: false,                null: false
      t.boolean  'opened',                  default: false,                null: false
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.integer  'client_id',               limit: 8,                      null: false
      t.boolean  'bounced',                 default: false,                null: false
    end
    add_index 'digest_mails', ['client_id'], name: 'index_digest_mails_on_client_id', using: :btree
    add_index 'digest_mails', ['code'], name: 'index_digest_mails_on_code', unique: true, using: :btree


    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_digest_mailing_batch_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('digest_mailing_batches_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE digest_mailing_batches ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE digest_mailing_batches ALTER COLUMN id SET DEFAULT generate_next_digest_mailing_batch_id();
      ALTER TABLE digest_mailing_batches ALTER COLUMN id SET NOT NULL;

    SQL


    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_digest_mailing_setting_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('digest_mailing_settings_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE digest_mailing_settings ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE digest_mailing_settings ALTER COLUMN id SET DEFAULT generate_next_digest_mailing_setting_id();
      ALTER TABLE digest_mailing_settings ALTER COLUMN id SET NOT NULL;

    SQL



    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_digest_mailing_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('digest_mailings_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE digest_mailings ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE digest_mailings ALTER COLUMN id SET DEFAULT generate_next_digest_mailing_id();
      ALTER TABLE digest_mailings ALTER COLUMN id SET NOT NULL;

    SQL




    execute <<-SQL

      CREATE OR REPLACE FUNCTION generate_next_digest_mail_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('digest_mails_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;


      ALTER TABLE digest_mails ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE digest_mails ALTER COLUMN id SET DEFAULT generate_next_digest_mail_id();
      ALTER TABLE digest_mails ALTER COLUMN id SET NOT NULL;

    SQL



  end
end
