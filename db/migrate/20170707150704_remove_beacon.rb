class RemoveBeacon < ActiveRecord::Migration
  def up
    drop_table :beacon_messages
  end

  def down
    create_table "beacon_messages", id: :bigserial, force: :cascade do |t|
      t.integer  "shop_id"
      t.integer  "user_id",         limit: 8
      t.integer  "session_id",      limit: 8
      t.text     "params",                                      null: false
      t.boolean  "notified",                    default: false, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "deal_id",         limit: 255
      t.boolean  "tracked",                     default: false, null: false
      t.integer  "beacon_offer_id"
    end
  end
end
