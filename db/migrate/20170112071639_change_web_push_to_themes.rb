class ChangeWebPushToThemes < ActiveRecord::Migration
  def change
    add_column :web_push_subscriptions_settings, :theme_id, :integer, limit: 8
    add_column :web_push_subscriptions_settings, :theme_type, :string
    add_index :web_push_subscriptions_settings, [:shop_id, :theme_id, :theme_type], name: 'index_web_push_subscriptions_settings_theme'
  end
end
