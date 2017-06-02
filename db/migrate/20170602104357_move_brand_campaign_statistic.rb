class MoveBrandCampaignStatistic < ActiveRecord::Migration
  def up
    create_table "brand_campaign_statistics", force: :cascade do |t|
      t.integer  "views",                 default: 0,   null: false
      t.integer  "original_purchases",    default: 0,   null: false
      t.integer  "recommended_purchases", default: 0,   null: false
      t.float    "cost",                  default: 0.0, null: false
      t.date     "date",                                null: false
      t.datetime "created_at",                          null: false
      t.datetime "updated_at",                          null: false
      t.integer  "recommended_clicks",    default: 0,   null: false
      t.integer  "original_clicks",       default: 0,   null: false
      t.integer  "brand_campaign_id"
    end

    config_master = ActiveRecord::Base.configurations["#{Rails.env}_master"]
    connection_string = "hostaddr=#{config_master['host'] == 'localhost' ? '127.0.0.1' : config_master['host']} dbname=#{config_master['database']} user=#{config_master['username']} password=#{config_master['password']} port=#{config_master['port'] || 5432}"

    columns = ActiveRecord::Base.connection.columns('brand_campaign_statistics')
    fields_list = columns.map { |x| '"' + x.name + '"' }.join(',')
    fields_with_type = columns.map {|v| '"' + v.name + '" ' + v.sql_type  + (v.array == true ? '[]' : '') }.join(', ')

    execute <<-SQL
      INSERT INTO brand_campaign_statistics (#{fields_list})
        SELECT * FROM
          dblink(
            '#{connection_string}',
            'SELECT #{fields_list} FROM brand_campaign_statistics')
          AS t1(#{fields_with_type});
      SELECT setval('brand_campaign_statistics_id_seq', COALESCE((SELECT MAX(id) FROM brand_campaign_statistics), 1), false);
    SQL

    add_index "brand_campaign_statistics", ["brand_campaign_id", "date"], name: "index_brand_campaign_statistics_on_brand_campaign_id_and_date", unique: true, using: :btree




    create_table "brand_campaign_statistics_events", force: :cascade do |t|
      t.integer  "brand_campaign_statistic_id",                 null: false
      t.integer  "brand_campaign_shop_id",                      null: false
      t.string   "recommender"
      t.string   "event",                                       null: false
      t.boolean  "recommended",                 default: false, null: false
      t.datetime "created_at",                                  null: false
      t.datetime "updated_at",                                  null: false
    end

    config_master = ActiveRecord::Base.configurations["#{Rails.env}_master"]
    connection_string = "hostaddr=#{config_master['host'] == 'localhost' ? '127.0.0.1' : config_master['host']} dbname=#{config_master['database']} user=#{config_master['username']} password=#{config_master['password']} port=#{config_master['port'] || 5432}"

    columns = ActiveRecord::Base.connection.columns('brand_campaign_statistics_events')
    fields_list = columns.map { |x| '"' + x.name + '"' }.join(',')
    fields_with_type = columns.map {|v| '"' + v.name + '" ' + v.sql_type  + (v.array == true ? '[]' : '') }.join(', ')

    execute <<-SQL
      INSERT INTO brand_campaign_statistics_events (#{fields_list})
        SELECT * FROM
          dblink(
            '#{connection_string}',
            'SELECT #{fields_list} FROM brand_campaign_statistics_events')
          AS t1(#{fields_with_type});
      SELECT setval('brand_campaign_statistics_events_id_seq', COALESCE((SELECT MAX(id) FROM brand_campaign_statistics_events), 1), false);
    SQL

    add_index "brand_campaign_statistics_events", ["brand_campaign_statistic_id", "brand_campaign_shop_id", "recommended", "event"], name: "index_brand_campaign_statistics_events_campaign_and_shop", using: :btree

  end

  def down
    drop_table :brand_campaign_statistics
    drop_table :brand_campaign_statistics_events
  end
end
