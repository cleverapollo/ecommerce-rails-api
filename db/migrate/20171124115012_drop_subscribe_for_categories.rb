class DropSubscribeForCategories < ActiveRecord::Migration
  def up
    drop_table :subscribe_for_categories
  end

  def down
    create_table "subscribe_for_categories", id: :bigserial, force: :cascade do |t|
      t.integer  "shop_id"
      t.integer  "user_id",          limit: 8
      t.integer  "item_category_id", limit: 8
      t.datetime "subscribed_at"
    end
  end
end
