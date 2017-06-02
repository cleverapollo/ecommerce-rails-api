class MoveBrandCampaignShop < ActiveRecord::Migration
  def up
    create_table "brand_campaign_shops", force: :cascade do |t|
      t.integer  "shop_id"
      t.datetime "last_event_at"
      t.integer  "brand_campaign_id"
      t.datetime "created_at",        null: false
      t.datetime "updated_at",        null: false
    end

    config_master = ActiveRecord::Base.configurations["#{Rails.env}_master"]
    connection_string = "hostaddr=#{config_master['host'] == 'localhost' ? '127.0.0.1' : config_master['host']} dbname=#{config_master['database']} user=#{config_master['username']} password=#{config_master['password']} port=#{config_master['port'] || 5432}"

    columns = ActiveRecord::Base.connection.columns('brand_campaign_shops')
    fields_list = columns.map { |x| '"' + x.name + '"' }.join(',')
    fields_with_type = columns.map {|v| '"' + v.name + '" ' + v.sql_type  + (v.array == true ? '[]' : '') }.join(', ')

    execute <<-SQL
      INSERT INTO brand_campaign_shops (#{fields_list})
        SELECT * FROM
          dblink(
            '#{connection_string}',
            'SELECT #{fields_list} FROM brand_campaign_shops')
          AS t1(#{fields_with_type});
      SELECT setval('brand_campaign_shops_id_seq', COALESCE((SELECT MAX(id) FROM brand_campaign_shops), 1), false);
    SQL

    add_index "brand_campaign_shops", ["brand_campaign_id"], name: "index_brand_campaign_shops_on_brand_campaign_id", using: :btree
    add_index "brand_campaign_shops", ["shop_id"], name: "index_brand_campaign_shops_on_shop_id", using: :btree
  end

  def down
    drop_table :brand_campaign_shops
  end
end
