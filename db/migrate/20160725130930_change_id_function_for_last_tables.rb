class ChangeIdFunctionForLastTables < ActiveRecord::Migration
  def change

    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_audience_segment_statistics_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('audience_segment_statistics_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE audience_segment_statistics ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE audience_segment_statistics ALTER COLUMN id SET DEFAULT generate_next_audience_segment_statistics_id();
      ALTER TABLE audience_segment_statistics ALTER COLUMN id SET NOT NULL;
    SQL


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_catalog_import_logs_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('catalog_import_logs_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE catalog_import_logs ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE catalog_import_logs ALTER COLUMN id SET DEFAULT generate_next_catalog_import_logs_id();
      ALTER TABLE catalog_import_logs ALTER COLUMN id SET NOT NULL;
    SQL


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_shop_metrics_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('shop_metrics_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE shop_metrics ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE shop_metrics ALTER COLUMN id SET DEFAULT generate_next_shop_metrics_id();
      ALTER TABLE shop_metrics ALTER COLUMN id SET NOT NULL;
    SQL




    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_subscribe_for_categories_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('subscribe_for_categories_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE subscribe_for_categories ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE subscribe_for_categories ALTER COLUMN id SET DEFAULT generate_next_subscribe_for_categories_id();
      ALTER TABLE subscribe_for_categories ALTER COLUMN id SET NOT NULL;
    SQL


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_subscribe_for_product_availables_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('subscribe_for_product_availables_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE subscribe_for_product_availables ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE subscribe_for_product_availables ALTER COLUMN id SET DEFAULT generate_next_subscribe_for_product_availables_id();
      ALTER TABLE subscribe_for_product_availables ALTER COLUMN id SET NOT NULL;
    SQL



    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_subscribe_for_product_prices_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('subscribe_for_product_prices_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE subscribe_for_product_prices ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE subscribe_for_product_prices ALTER COLUMN id SET DEFAULT generate_next_subscribe_for_product_prices_id();
      ALTER TABLE subscribe_for_product_prices ALTER COLUMN id SET NOT NULL;
    SQL



    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_trigger_mailing_queues_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('trigger_mailing_queues_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE trigger_mailing_queues ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE trigger_mailing_queues ALTER COLUMN id SET DEFAULT generate_next_trigger_mailing_queues_id();
      ALTER TABLE trigger_mailing_queues ALTER COLUMN id SET NOT NULL;
    SQL


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_web_push_subscriptions_settings_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('web_push_subscriptions_settings_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE web_push_subscriptions_settings ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE web_push_subscriptions_settings ALTER COLUMN id SET DEFAULT generate_next_web_push_subscriptions_settings_id();
      ALTER TABLE web_push_subscriptions_settings ALTER COLUMN id SET NOT NULL;
    SQL


    execute <<-SQL
      CREATE OR REPLACE FUNCTION generate_next_web_push_triggers_id(OUT result bigint) AS $$
            DECLARE
            our_epoch bigint := 1314220021721;
            seq_id bigint;
            now_millis bigint;
            shard_id int := #{SHARD_ID};
            BEGIN
              SELECT nextval('web_push_triggers_id_seq')::BIGINT % 1024 INTO seq_id;
              SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
              result := (now_millis - our_epoch) << 23;
              result := result | (shard_id << 10);
              result := result | (seq_id);
              END;
              $$ LANGUAGE PLPGSQL;
      ALTER TABLE web_push_triggers ALTER COLUMN id TYPE BIGINT;
      ALTER TABLE web_push_triggers ALTER COLUMN id SET DEFAULT generate_next_web_push_triggers_id();
      ALTER TABLE web_push_triggers ALTER COLUMN id SET NOT NULL;
    SQL








  end
end
