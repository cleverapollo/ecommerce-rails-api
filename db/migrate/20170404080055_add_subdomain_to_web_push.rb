class AddSubdomainToWebPush < ActiveRecord::Migration
  def change
    add_column :web_push_subscriptions_settings, :subdomain, :string
    add_index :web_push_subscriptions_settings, :subdomain, unique: true
  end
end
