


namespace :shards do

  # All tasks
  # RAILS_ENV=production bundle exec rake shards:transfer_actions
  # RAILS_ENV=production bundle exec rake shards:transfer_items
  # RAILS_ENV=production bundle exec rake shards:transfer_beacon_messages
  # RAILS_ENV=production bundle exec rake shards:transfer_client_errors
  # RAILS_ENV=production bundle exec rake shards:transfer_digest_mailings
  # RAILS_ENV=production bundle exec rake shards:transfer_digest_mailing_batches
  # RAILS_ENV=production bundle exec rake shards:transfer_digest_mailing_settings
  # RAILS_ENV=production bundle exec rake shards:transfer_digest_mails
  # RAILS_ENV=production bundle exec rake shards:transfer_mailings_settings
  # RAILS_ENV=production bundle exec rake shards:transfer_trigger_mailings
  # RAILS_ENV=production bundle exec rake shards:transfer_trigger_mails
  # RAILS_ENV=production bundle exec rake shards:transfer_events
  # RAILS_ENV=production bundle exec rake shards:transfer_clients
  # RAILS_ENV=production bundle exec rake shards:transfer_orders
  # RAILS_ENV=production bundle exec rake shards:transfer_order_items
  # RAILS_ENV=production bundle exec rake shards:transfer_item_categories
  # RAILS_ENV=production bundle exec rake shards:transfer_recommendations_requests
  # RAILS_ENV=production bundle exec rake shards:transfer_interactions


  # transfer_connection_string = "dbname=postgres hostaddr=#{MASTER_DB['host']} dbname=#{MASTER_DB['database']} user=#{MASTER_DB['username']} password=#{MASTER_DB['password']} port=#{MASTER_DB['port']}"

  desc 'Transfer actions'
  task :transfer_actions => :environment do
    max_id = Action.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'actions'
    fields = {id: "bigint", user_id: "bigint", item_id: "bigint", view_count: "integer", view_date: "timestamp without time zone", cart_count: "integer", cart_date: "timestamp without time zone", purchase_count: "integer", purchase_date: "timestamp without time zone", rating: "double precision", shop_id: "integer", timestamp: "integer", recommended_by: "character varying(255)", last_action: "smallint", rate_count: "integer", rate_date: "timestamp without time zone", last_user_rating: "integer", repeatable: "boolean", recommended_at: "timestamp without time zone"}
    # fields = 'id, user_id, item_id, view_count, view_date, cart_count, cart_date, purchase_count, purchase_date, rating, shop_id, timestamp, recommended_by, last_action, rate_count, rate_date, last_user_rating, repeatable, recommended_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields.keys})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields.keys} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, user_id bigint, item_id bigint, view_count integer, view_date timestamp without time zone, cart_count integer, cart_date timestamp without time zone, purchase_count integer, purchase_date timestamp without time zone, rating double precision, shop_id integer, timestamp integer, recommended_by character varying(255), last_action smallint, rate_count integer, rate_date timestamp without time zone, last_user_rating integer, repeatable boolean, recommended_at timestamp without time zone);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer items'
  task :transfer_items => :environment do
    max_id = Item.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'items'
    fields = 'id, shop_id, uniqid, price, is_available, name, description, url, image_url, tags, widgetable, brand, repeatable, available_till, categories, ignored, custom_attributes, locations, sr, sales_rate, type_prefix, vendor_code, model, gender, wear_type, feature, sizes, age_min, age_max'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, uniqid character varying(255), price numeric, is_available boolean, name character varying(255), description text, url text, image_url text, tags character varying[], widgetable boolean, brand character varying(255), repeatable boolean, available_till date, categories character varying[], ignored boolean, custom_attributes jsonb, locations jsonb, sr double precision, sales_rate smallint, type_prefix character varying, vendor_code character varying, model character varying, gender character varying(1), wear_type character varying(20), feature character varying(20), sizes character varying[], age_min float, age_max float);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer beacon_messages'
  task :transfer_beacon_messages => :environment do
    max_id = BeaconMessage.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'beacon_messages'
    fields = 'id, shop_id, user_id, session_id, params, notified, created_at, updated_at, deal_id, tracked'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, user_id bigint, session_id bigint, params text, notified boolean, created_at timestamp without time zone, updated_at timestamp without time zone, deal_id character varying(255), tracked boolean);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer client_errors'
  task :transfer_client_errors => :environment do
    max_id = ClientError.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'client_errors'
    fields = 'id, shop_id, exception_class, exception_message, params, resolved, created_at, updated_at, referer'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, exception_class character varying(255), exception_message character varying(255), params text, resolved boolean, created_at timestamp without time zone, updated_at timestamp without time zone, referer character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer digest_mailings'
  task :transfer_digest_mailings => :environment do
    max_id = DigestMailing.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'digest_mailings'
    fields = 'id, shop_id, name, subject, template, items, state, created_at, updated_at, item_template, total_mails_count, started_at, finished_at, header, text, edit_mode'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, name character varying(255), subject character varying(255), template text, items character varying(255), state character varying(255), created_at timestamp without time zone, updated_at timestamp without time zone, item_template text, total_mails_count integer, started_at timestamp without time zone, finished_at timestamp without time zone, header text, text text, edit_mode character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer digest_mailing_batches'
  task :transfer_digest_mailing_batches => :environment do
    max_id = DigestMailingBatch.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'digest_mailing_batches'
    fields = 'id, digest_mailing_id, end_id, completed, start_id, test_email'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE digest_mailing_id IN (SELECT id FROM digest_mailings WHERE (shop_id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, digest_mailing_id bigint, end_id bigint, completed boolean, start_id bigint, test_email character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer digest_mailing_settings'
  task :transfer_digest_mailing_settings => :environment do
    max_id = DigestMailingSetting.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'digest_mailing_settings'
    fields = 'id, shop_id, "on", sender'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, "on" boolean, sender character varying(255));
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer digest_mails'
  task :transfer_digest_mails => :environment do
    max_id = DigestMail.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'digest_mails'
    fields = 'id, shop_id, digest_mailing_id, digest_mailing_batch_id, code, clicked, opened, created_at, updated_at, client_id, bounced'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, digest_mailing_id bigint, digest_mailing_batch_id bigint, code uuid, clicked boolean, opened boolean, created_at timestamp without time zone, updated_at timestamp without time zone, client_id bigint, bounced boolean);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer mailings_settings'
  task :transfer_mailings_settings => :environment do
    max_id = MailingsSettings.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'mailings_settings'
    fields = 'id, shop_id, send_from, created_at, updated_at, logo_file_name, logo_content_type, logo_file_size, logo_updated_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, send_from character varying(255), created_at timestamp without time zone, updated_at timestamp without time zone, logo_file_name character varying(255), logo_content_type character varying(255), logo_file_size integer, logo_updated_at timestamp without time zone);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer trigger_mailings'
  task :transfer_trigger_mailings => :environment do
    max_id = TriggerMailing.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'trigger_mailings'
    fields = 'id, shop_id, trigger_type, subject, template, item_template, enabled, created_at, updated_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, trigger_type character varying(255), subject character varying(255), template text, item_template text, enabled boolean, created_at timestamp without time zone, updated_at timestamp without time zone);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer trigger_mails'
  task :transfer_trigger_mails => :environment do
    max_id = TriggerMail.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'trigger_mails'
    fields = 'id, shop_id, trigger_data, code, clicked, created_at, updated_at, opened, trigger_mailing_id, bounced, client_id'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, trigger_data text, code uuid, clicked boolean, created_at timestamp without time zone, updated_at timestamp without time zone, opened boolean, trigger_mailing_id bigint, bounced boolean, client_id bigint);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer events'
  task :transfer_events => :environment do
    max_id = Event.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'events'
    fields = 'id, shop_id, name, additional_info, created_at, updated_at, processed'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, name character varying(255), additional_info text, created_at timestamp without time zone, updated_at timestamp without time zone, processed boolean);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer clients'
  task :transfer_clients => :environment do
    max_id = Client.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'clients'
    fields = 'id, shop_id, user_id, bought_something, ab_testing_group, created_at, updated_at, external_id, email, digests_enabled, code, subscription_popup_showed, triggers_enabled, last_trigger_mail_sent_at, accepted_subscription, location'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, user_id bigint, bought_something boolean, ab_testing_group integer, created_at timestamp, updated_at timestamp, external_id character varying(255), email character varying(255), digests_enabled boolean, code uuid, subscription_popup_showed boolean, triggers_enabled boolean, last_trigger_mail_sent_at timestamp, accepted_subscription boolean, location character varying);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer orders'
  task :transfer_orders => :environment do
    max_id = Order.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'orders'
    fields = 'id, shop_id, user_id, uniqid, date, value, recommended, ab_testing_group, recommended_value, common_value, source_id, source_type, status, status_date'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, user_id bigint, uniqid character varying(255), "date" timestamp, value numeric, recommended boolean, ab_testing_group integer, recommended_value numeric, common_value numeric, source_id integer, source_type character varying, status integer, status_date timestamp);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer order_items'
  task :transfer_order_items => :environment do
    max_id = OrderItem.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'order_items'
    fields = 'id, order_id, item_id, action_id, amount, recommended_by'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE order_id IN (SELECT id FROM orders WHERE (shop_id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, order_id bigint, item_id bigint, action_id bigint, amount integer, recommended_by character varying);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer item_categories'
  task :transfer_item_categories => :environment do
    max_id = ItemCategory.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'item_categories'
    fields = 'id, shop_id, parent_id, external_id, parent_external_id, name, created_at, updated_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, parent_id integer, external_id character varying, parent_external_id character varying, name character varying, created_at timestamp, updated_at timestamp);
    SQL
    ActiveRecord::Base.connection.execute query
  end

  desc 'Transfer recommendations_requests'
  task :transfer_recommendations_requests => :environment do
    max_id = RecommendationsRequest.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'recommendations_requests'
    fields = 'id, shop_id, category_id, recommender_type, clicked, recommendations_count, recommended_ids, duration, user_id, session_code, created_at, updated_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, category_id integer, recommender_type character varying(255), clicked boolean, recommendations_count integer, recommended_ids text[], duration numeric, user_id bigint, session_code character varying(255), created_at timestamp, updated_at timestamp);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer interactions'
  task :transfer_interactions => :environment do
    max_id = Interaction.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0]
    table_name = 'interactions'
    fields = 'id, shop_id, user_id, item_id, code, recommender_code, created_at'
    query = <<-SQL
      INSERT INTO #{table_name} (#{fields})
        SELECT * FROM
          dblink(
            '#{transfer_connection_string}',
            'SELECT #{fields} FROM #{table_name} WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id integer, user_id bigint, item_id bigint, code integer, recommender_code integer, created_at timestamp);
    SQL
    ActiveRecord::Base.connection.execute query
  end

end
