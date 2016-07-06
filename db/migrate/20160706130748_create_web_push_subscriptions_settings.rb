class CreateWebPushSubscriptionsSettings < ActiveRecord::Migration
  def change

    create_table :web_push_subscriptions_settings, id: :bigserial, force: :cascade do |t|
      t.integer  "shop_id",                                          null: false
      t.boolean  "enabled",                          default: false, null: false
      t.boolean  "overlay",                          default: true,  null: false
      t.text     "header",                                           null: false
      t.text     "text",                                             null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "picture_file_name",    limit: 255
      t.string   "picture_content_type", limit: 255
      t.integer  "picture_file_size"
      t.datetime "picture_updated_at"
      t.text     "css"
      t.string   "button"
      t.text     "agreement"
    end

  end
end
