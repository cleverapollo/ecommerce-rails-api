class AddSafariSettingToWebPushSubscriptionsSettings < ActiveRecord::Migration
  def change
    add_column :web_push_subscriptions_settings, :safari_website_push_id, :string
    add_column :web_push_subscriptions_settings, :certificate_password, :string
    add_attachment :web_push_subscriptions_settings, :certificate
  end
end
