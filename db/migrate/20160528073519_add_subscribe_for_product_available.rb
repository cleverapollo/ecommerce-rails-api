class AddSubscribeForProductAvailable < ActiveRecord::Migration
  def change

    create_table "subscribe_for_product_prices", force: :cascade do |t|
      t.integer  "shop_id"
      t.integer  "user_id",          limit: 8
      t.integer  "item_id", limit: 8
      t.datetime "subscribed_at"
    end

    add_index "subscribe_for_product_prices", ["shop_id", "user_id", "item_id"], name: 'index_subscribe_for_product_price_uniq', unique: true
    add_index "subscribe_for_product_prices", ["shop_id", "user_id"], name: 'index_subscribe_for_product_price_for_user'

    create_table "subscribe_for_product_availables", force: :cascade do |t|
      t.integer  "shop_id"
      t.integer  "user_id",          limit: 8
      t.integer  "item_id", limit: 8
      t.datetime "subscribed_at"
    end

    add_index "subscribe_for_product_availables", ["shop_id", "user_id", "item_id"], name: 'index_subscribe_for_product_available_uniq', unique: true
    add_index "subscribe_for_product_availables", ["shop_id", "user_id"], name: 'index_subscribe_for_product_available_for_user'

  end
end
