class CreateWebPushTriggers < ActiveRecord::Migration
  def change
    create_table :web_push_triggers do |t|
      t.integer  "shop_id",                                                 null: false
      t.string   "trigger_type",                limit: 255,                 null: false
      t.string   "message",                     limit: 255,                 null: false
      t.boolean  "enabled",                                 default: false, null: false
      t.timestamps null: false
    end
  end
end
