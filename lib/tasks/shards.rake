namespace :shards do

  desc 'Transfer actions'
  task :transfer_actions => :environment do
    table_name = 'actions'
    fields = 'id, user_id, item_id, view_count, view_date, cart_count, cart_date, purchase_count, purchase_date, rating, shop_id, timestamp, recommended_by, last_action, rate_count, rate_date, last_user_rating, repeatable, recommended_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, user_id bigint, item_id bigint, view_count integer, view_date timestamp without time zone, cart_count integer, cart_date timestamp without time zone, purchase_count integer, purchase_date timestamp without time zone, rating double precision, shop_id integer, timestamp integer, recommended_by character varying(255), last_action smallint, rate_count integer, rate_date timestamp without time zone, last_user_rating integer, repeatable boolean, recommended_at timestamp without time zone);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer items'
  task :transfer_items => :environment do
    table_name = 'items'
    fields = 'id, shop_id, uniqid, price, is_available, name, description, url, image_url, tags, widgetable, brand, repeatable, available_till, categories, ignored, custom_attributes, locations, sr, sales_rate, type_prefix, vendor_code, model, gender, wear_type, feature, sizes'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, uniqid character varying(255), price numeric, is_available boolean, name character varying(255), description text, url text, image_url text, tags character varying[], widgetable boolean, brand character varying(255), repeatable boolean, available_till date, categories character varying[], ignored boolean, custom_attributes jsonb, locations jsonb, sr double precision, sales_rate smallint, type_prefix character varying, vendor_code character varying, model character varying, gender character varying(1), wear_type character varying(20), feature character varying(20), sizes character varying[]);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer beacon_messages'
  task :transfer_beacon_messages => :environment do
    table_name = 'beacon_messages'
    fields = 'id, shop_id, user_id, session_id, params, notified, created_at, updated_at, deal_id, tracked'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, user_id bigint, session_id bigint, params text, notified boolean, created_at timestamp without time zone, updated_at timestamp without time zone, deal_id character varying(255), tracked boolean);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer client_errors'
  task :transfer_client_errors => :environment do
    table_name = 'client_errors'
    fields = 'id, shop_id, exception_class, exception_message, params, resolved, created_at, updated_at, referer'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, exception_class character varying(255), exception_message character varying(255), params text, resolved boolean, created_at timestamp without time zone, updated_at timestamp without time zone, referer character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer digest_mailings'
  task :transfer_digest_mailings => :environment do
    table_name = 'digest_mailings'
    fields = 'id, shop_id, name, subject, template, items, state, created_at, updated_at, item_template, total_mails_count, started_at, finished_at, header, text, edit_mode'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, name character varying(255), subject character varying(255), template text, items character varying(255), state character varying(255), created_at timestamp without time zone, updated_at timestamp without time zone, item_template text, total_mails_count integer, started_at timestamp without time zone, finished_at timestamp without time zone, header text, text text, edit_mode character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer digest_mailing_batches'
  task :transfer_digest_mailing_batches => :environment do
    table_name = 'digest_mailing_batches'
    fields = 'id, digest_mailing_id, end_id, completed, start_id, test_email'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE digest_mailing_id IN (SELECT id FROM digest_mailings WHERE (shop_id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, digest_mailing_id bigint, end_id bigint, completed boolean, start_id bigint, test_email character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer digest_mailing_settings'
  task :transfer_digest_mailing_settings => :environment do
    table_name = 'digest_mailing_settings'
    fields = 'id, shop_id, "on", sender'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, "on" boolean, sender character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer digest_mails'
  task :transfer_digest_mails => :environment do
    table_name = 'digest_mails'
    fields = 'id, shop_id, digest_mailing_id, digest_mailing_batch_id, code, clicked, opened, created_at, updated_at, client_id, bounced'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, digest_mailing_id bigint, digest_mailing_batch_id bigint, code uuid, clicked boolean, opened boolean, created_at timestamp without time zone, updated_at timestamp without time zone, client_id bigint, bounced boolean);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer mailings_settings'
  task :transfer_mailings_settings => :environment do
    table_name = 'mailings_settings'
    fields = 'id, shop_id, send_from, created_at, updated_at, logo_file_name, logo_content_type, logo_file_size, logo_updated_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, send_from character varying(255), created_at timestamp without time zone, updated_at timestamp without time zone, logo_file_name character varying(255), logo_content_type character varying(255), logo_file_size integer, logo_updated_at timestamp without time zone);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer trigger_mailings'
  task :transfer_trigger_mailings => :environment do
    table_name = 'trigger_mailings'
    fields = 'id, shop_id, trigger_type, subject, template, item_template, enabled, created_at, updated_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, trigger_type character varying(255), subject character varying(255), template text, item_template text, enabled boolean, created_at timestamp without time zone, updated_at timestamp without time zone);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer trigger_mails'
  task :transfer_trigger_mails => :environment do
    table_name = 'trigger_mails'
    fields = 'id, shop_id, trigger_data, code, clicked, created_at, updated_at, opened, trigger_mailing_id, bounced, client_id'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, trigger_data text, code uuid, clicked boolean, created_at timestamp without time zone, updated_at timestamp without time zone, opened boolean, trigger_mailing_id bigint, bounced boolean, client_id bigint);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer events'
  task :transfer_events => :environment do
    table_name = 'events'
    fields = 'id, shop_id, name, additional_info, created_at, updated_at, processed'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, name character varying(255), additional_info text, created_at timestamp without time zone, updated_at timestamp without time zone, processed boolean);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer clients'
  task :transfer_clients => :environment do
    table_name = 'clients'
    fields = 'id, shop_id, user_id, bought_something, ab_testing_group, created_at, updated_at, external_id, email, digests_enabled, code, subscription_popup_showed, triggers_enabled, last_trigger_mail_sent_at, accepted_subscription, location'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, user_id bigint, bought_something boolean, ab_testing_group integer, created_at timestamp, updated_at timestamp, external_id character varying(255), email character varying(255), digests_enabled boolean, code character varying(255), subscription_popup_showed boolean, triggers_enabled boolean, last_trigger_mail_sent_at timestamp, accepted_subscription boolean, location character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end

end

