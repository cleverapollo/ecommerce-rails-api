module Sharding
  class DataManager

    def initialize
      @connection_string = "dbname=postgres hostaddr=#{MASTER_DB['host']} dbname=#{MASTER_DB['database']} user=#{MASTER_DB['username']} password=#{MASTER_DB['password']} port=#{MASTER_DB['port']}"
    end

    def transfer_all(only_new = false)
      puts "Processing transfer_actions"
      transfer_actions only_new
      puts "Processing transfer_items"
      transfer_items only_new
      puts "Processing transfer_beacon_messages"
      transfer_beacon_messages only_new
      puts "Processing transfer"
      transfer_client_errors only_new
      puts "Processing transfer_digestmailings"
      transfer_digest_mailings only_new
      puts "Processing transfer_digest_mailing_batches"
      transfer_digest_mailing_batches only_new
      puts "Processing transfer_digest_mailing_settings"
      transfer_digest_mailing_settings only_new
      puts "Processing transfer_digest_mails"
      transfer_digest_mails only_new
      puts "Processing transfer_mailings_settings"
      transfer_mailings_settings only_new
      puts "Processing transfer_trigger_mailings"
      transfer_trigger_mailings only_new
      puts "Processing transfer_trigger_mails"
      transfer_trigger_mails only_new
      puts "Processing transfer_events"
      transfer_events only_new
      puts "Processing transfer_clients"
      transfer_clients only_new
      puts "Processing transfer_orders"
      transfer_orders only_new
      puts "Processing transfer_order_items"
      transfer_order_items only_new
      puts "Processing transfer_item_categories"
      transfer_item_categories only_new
      puts "Processing transfer_recommendations_requests"
      transfer_recommendations_requests only_new
      puts "Processing transfer_interactions"
      transfer_interactions only_new
    end


    def transfer_actions(only_new = false)
      max_id = only_new ? max_id = Action.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'actions'
      fields = {id: "bigint", user_id: "bigint", item_id: "bigint", view_count: "integer", view_date: "timestamp without time zone", cart_count: "integer", cart_date: "timestamp without time zone", purchase_count: "integer", purchase_date: "timestamp without time zone", rating: "double precision", shop_id: "integer", timestamp: "integer", recommended_by: "character varying(255)", last_action: "smallint", rate_count: "integer", rate_date: "timestamp without time zone", last_user_rating: "integer", repeatable: "boolean", recommended_at: "timestamp without time zone"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_items(only_new = false)
      max_id = only_new ? max_id = Item.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'items'
      fields = {id: "bigint", shop_id: "integer", uniqid: "character varying(255)", price: "numeric", is_available: "boolean", name: "character varying(255)", description: "text", url: "text", image_url: "text", tags: "character varying[]", widgetable: "boolean", brand: "character varying(255)", repeatable: "boolean", available_till: "date", categories: "character varying[]", ignored: "boolean", custom_attributes: "jsonb", locations: "jsonb", sr: "double precision", sales_rate: "smallint", type_prefix: "character varying", vendor_code: "character varying", model: "character varying", gender: "character varying(1)", wear_type: "character varying(20)", feature: "character varying(20)", sizes: "character varying[]", age_min: "float", age_max: "float"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_beacon_messages(only_new = false)
      max_id = only_new ? max_id = BeaconMessage.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'beacon_messages'
      fields = {id: "bigint", shop_id: "integer", user_id: "bigint", session_id: "bigint", params: "text", notified: "boolean", created_at: "timestamp without time zone", updated_at: "timestamp without time zone", deal_id: "character varying(255)", tracked: "boolean"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end

    def transfer_client_errors(only_new = false)
      max_id = only_new ? max_id = ClientError.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'client_errors'
      fields = {id: "bigint", shop_id: "integer", exception_class: "character varying(255)", exception_message: "character varying(255)", params: "text", resolved: "boolean", created_at: "timestamp without time zone", updated_at: "timestamp without time zone", referer: "character varying(255)"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_digest_mailings(only_new = false)
      max_id = only_new ? max_id = DigestMailing.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'digest_mailings'
      fields = {id: "bigint", shop_id: "integer", name: "character varying(255)", subject: "character varying(255)", template: "text", items: "character varying(255)", state: "character varying(255)", created_at: "timestamp without time zone", updated_at: "timestamp without time zone", item_template: "text", total_mails_count: "integer", started_at: "timestamp without time zone", finished_at: "timestamp without time zone", header: "text", text: "text", edit_mode: "character varying(255)"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end

    def transfer_digest_mailing_batches(only_new = false)
      max_id = only_new ? max_id = DigestMailingBatch.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'digest_mailing_batches'
      fields = {id: "bigint", digest_mailing_id: "bigint", end_id: "bigint", completed: "boolean", start_id: "bigint", test_email: "character varying(255)"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND digest_mailing_id IN (SELECT id FROM digest_mailings WHERE (shop_id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end

    def transfer_digest_mailing_settings(only_new = false)
      max_id = only_new ? max_id = DigestMailingSetting.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'digest_mailing_settings'
      fields = {id: "bigint", shop_id: "integer", '"on"': "boolean", sender: "character varying(255)"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end

    def transfer_digest_mails(only_new = false)
      max_id = only_new ? max_id = DigestMail.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'digest_mails'
      fields = {id: "bigint", shop_id: "integer", digest_mailing_id: "bigint", digest_mailing_batch_id: "bigint", code: "uuid", clicked: "boolean", opened: "boolean", created_at: "timestamp without time zone", updated_at: "timestamp without time zone", client_id: "bigint", bounced: "boolean"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end

    def transfer_mailings_settings(only_new = false)
      max_id = only_new ? max_id = MailingsSettings.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'mailings_settings'
      fields = {id: "bigint", shop_id: "integer", send_from: "character varying(255)", created_at: "timestamp without time zone", updated_at: "timestamp without time zone", logo_file_name: "character varying(255)", logo_content_type: "character varying(255)", logo_file_size: "integer", logo_updated_at: "timestamp without time zone"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end

    def transfer_trigger_mailings(only_new = false)
      max_id = only_new ? max_id = TriggerMailing.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'trigger_mailings'
      fields = {id: "bigint", shop_id: "integer", trigger_type: "character varying(255)", subject: "character varying(255)", template: "text", item_template: "text", enabled: "boolean", created_at: "timestamp without time zone", updated_at: "timestamp without time zone"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_trigger_mails(only_new = false)
      max_id = only_new ? max_id = TriggerMail.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'trigger_mails'
      fields = {id: "bigint", shop_id: "integer", trigger_data: "text", code: "uuid", clicked: "boolean", created_at: "timestamp without time zone", updated_at: "timestamp without time zone", opened: "boolean", trigger_mailing_id: "bigint", bounced: "boolean", client_id: "bigint"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_events(only_new = false)
      max_id = only_new ? max_id = Event.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'events'
      fields = {id: "bigint", shop_id: "integer", name: "character varying(255)", additional_info: "text", created_at: "timestamp without time zone", updated_at: "timestamp without time zone", processed: "boolean"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end

    def transfer_clients(only_new = false)
      max_id = only_new ? max_id = Client.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'clients'
      fields = {id: "bigint", shop_id: "integer", user_id: "bigint", bought_something: "boolean", ab_testing_group: "integer", created_at: "timestamp", updated_at: "timestamp", external_id: "character varying(255)", email: "character varying(255)", digests_enabled: "boolean", code: "uuid", subscription_popup_showed: "boolean", triggers_enabled: "boolean", last_trigger_mail_sent_at: "timestamp", accepted_subscription: "boolean", location: "character varying"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_orders(only_new = false)
      max_id = only_new ? max_id = Order.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'orders'
      fields = {id: "bigint", shop_id: "integer", user_id: "bigint", uniqid: "character varying(255)", date: "timestamp", value: "numeric", recommended: "boolean", ab_testing_group: "integer", recommended_value: "numeric", common_value: "numeric", source_id: "integer", source_type: "character varying", status: "integer", status_date: "timestamp"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_order_items(only_new = false)
      max_id = only_new ? max_id = OrderItem.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'order_items'
      fields = {id: "bigint", order_id: "bigint", item_id: "bigint", action_id: "bigint", amount: "integer", recommended_by: "character varying"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND order_id IN (SELECT id FROM orders WHERE (shop_id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_item_categories(only_new = false)
      max_id = only_new ? max_id = ItemCategory.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'item_categories'
      fields = {id: "bigint", shop_id: "integer", parent_id: "integer", external_id: "character varying", parent_external_id: "character varying", name: "character varying", created_at: "timestamp", updated_at: "timestamp"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end

    def transfer_recommendations_requests(only_new = false)
      max_id = only_new ? max_id = RecommendationsRequest.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'recommendations_requests'
      fields = {id: "bigint", shop_id: "integer", category_id: "integer", recommender_type: "character varying(255)", clicked: "boolean", recommendations_count: "integer", recommended_ids: "text[]", duration: "numeric", user_id: "bigint", session_code: "character varying(255)", created_at: "timestamp", updated_at: "timestamp"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end


    def transfer_interactions(only_new = false)
      max_id = only_new ? max_id = Interaction.where('id < 2147483647').order(id: :desc).limit(1).pluck(:id)[0] : 0
      table_name = 'interactions'
      fields = {id: "bigint", shop_id: "integer", user_id: "bigint", item_id: "bigint", code: "integer", recommender_code: "integer", created_at: "timestamp"}
      fields_list = fields.keys.map {|x| x.to_s}.join(', ')
      fields_with_type = fields.to_a.map {|v| "#{v[0]} #{v[1]}" }.join(", ")
      query = <<-SQL
      INSERT INTO #{table_name} (#{fields_list})
        SELECT * FROM
          dblink(
            '#{@connection_string}',
            'SELECT #{fields_list} FROM #{table_name} WHERE id > #{max_id} AND shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(#{fields_with_type});
      SQL
      ActiveRecord::Base.connection.execute query
    end
    
    


  end
end
