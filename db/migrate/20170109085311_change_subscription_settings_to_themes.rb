class ChangeSubscriptionSettingsToThemes < ActiveRecord::Migration
  def change
    add_column :subscriptions_settings, :theme_id, :integer, limit: 8
    add_column :subscriptions_settings, :theme_type, :string
    add_index :subscriptions_settings, [:shop_id, :theme_id, :theme_type], name: 'index_subscriptions_settings_theme'
  end
end
