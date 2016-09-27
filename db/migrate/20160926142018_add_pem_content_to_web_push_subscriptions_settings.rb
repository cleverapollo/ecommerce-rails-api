class AddPemContentToWebPushSubscriptionsSettings < ActiveRecord::Migration
  def change
    add_column :web_push_subscriptions_settings, :pem_content, :text
  end
end
