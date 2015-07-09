namespace :shards do

  desc 'Transfer actions'
  task :transfer_actions => :environment do
    query = <<-SQL
      INSERT INTO actions (id, user_id, item_id, view_count, view_date, cart_count, cart_date, purchase_count, purchase_date, rating, shop_id, timestamp, recommended_by, last_action, rate_count, rate_date, last_user_rating, repeatable, recommended_at)
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT id, user_id, item_id, view_count, view_date, cart_count, cart_date, purchase_count, purchase_date, rating, shop_id, timestamp, recommended_by, last_action, rate_count, rate_date, last_user_rating, repeatable, recommended_at FROM actions WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, user_id bigint, item_id bigint, view_count integer, view_date timestamp without time zone, cart_count integer, cart_date timestamp without time zone, purchase_count integer, purchase_date timestamp without time zone, rating double precision, shop_id bigint, timestamp integer, recommended_by character varying(255), last_action smallint, rate_count integer, rate_date timestamp without time zone, last_user_rating integer, repeatable boolean, recommended_at timestamp without time zone);
    SQL
    ActiveRecord::Base.connection.execute query
  end


  desc 'Transfer items'
  task :transfer_items => :environment do
    query = <<-SQL
      INSERT INTO items (id, shop_id, uniqid, price, is_available, name, description, url, image_url, tags, widgetable, brand, repeatable, available_till, categories, ignored, custom_attributes, locations, sr, sales_rate, type_prefix, vendor_code, model, gender, wear_type, feature, sizes)
        SELECT * FROM
          dblink(
            'dbname=postgres hostaddr=#{MASTER_DB["host"]} dbname=#{MASTER_DB["database"]} user=#{MASTER_DB["username"]} password=#{MASTER_DB["password"]}',
            'SELECT id, shop_id, uniqid, price, is_available, name, description, url, image_url, tags, widgetable, brand, repeatable, available_till, categories, ignored, custom_attributes, locations, sr, sales_rate, type_prefix, vendor_code, model, gender, wear_type, feature, sizes FROM items WHERE shop_id IN (SELECT id FROM shops WHERE (id % 2) = #{SHARD_ID} )')
          AS t1(id bigint, shop_id bigint, uniqid character varying(255), price numeric, is_available boolean, name character varying(255), description text, url text, image_url text, tags character varying[], widgetable boolean, brand character varying(255), repeatable boolean, available_till date, categories character varying[], ignored boolean, custom_attributes jsonb, locations jsonb, sr double precision, sales_rate smallint, type_prefix character varying, vendor_code character varying, model character varying, gender character varying(1), wear_type character varying(20), feature character varying(20), sizes character varying[]);
    SQL
    ActiveRecord::Base.connection.execute query
  end

end

