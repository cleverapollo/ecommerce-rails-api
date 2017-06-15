class MoveProfileEvent < ActiveRecord::Migration

  def up

    create_table "profile_events", force: :cascade do |t|
      t.integer  "user_id",    limit: 8, null: false
      t.integer  "shop_id",              null: false
      t.string   "industry",             null: false
      t.string   "property",             null: false
      t.string   "value",                null: false
      t.integer  "views"
      t.integer  "carts"
      t.integer  "purchases"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    config_master = ActiveRecord::Base.configurations["#{Rails.env}_master"]
    connection_string = "hostaddr=#{config_master['host'] == 'localhost' ? '127.0.0.1' : config_master['host']} dbname=#{config_master['database']} user=#{config_master['username']} password=#{config_master['password']} port=#{config_master['port'] || 5432}"

    columns = ActiveRecord::Base.connection.columns('profile_events')
    fields_list = columns.map { |x| '"' + x.name + '"' }.join(',')
    fields_with_type = columns.map {|v| '"' + v.name + '" ' + v.sql_type  + (v.array == true ? '[]' : '') }.join(', ')

    execute <<-SQL
      INSERT INTO profile_events (#{fields_list})
        SELECT * FROM
          dblink(
            '#{connection_string}',
            'SELECT #{fields_list} FROM profile_events')
          AS t1(#{fields_with_type});
      SELECT setval('profile_events_id_seq', COALESCE((SELECT MAX(id) FROM profile_events), 1), false);
    SQL

    add_index "profile_events", ["user_id", "industry", "property"], name: "index_profile_events_on_user_id_and_industry_and_property", using: :btree
    add_index "profile_events", ["user_id", "shop_id", "industry", "property"], name: "index_profile_events_all_columns", using: :btree
    add_index "profile_events", ["user_id", "shop_id"], name: "index_profile_events_on_user_id_and_shop_id", using: :btree
    add_index "profile_events", ["user_id"], name: "index_profile_events_on_user_id", using: :btree

  end

  def down
    drop_table :profile_events
  end
end
