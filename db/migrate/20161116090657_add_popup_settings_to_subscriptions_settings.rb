class AddPopupSettingsToSubscriptionsSettings < ActiveRecord::Migration
  def change
    add_column :subscriptions_settings, :popup_type, :integer, null: false, default: 0
    add_column :subscriptions_settings, :timer, :integer, null: false, default: 90
    add_column :subscriptions_settings, :timer_enabled, :boolean, null: false, default: true
    add_column :subscriptions_settings, :pager, :integer, null: false, default: 5
    add_column :subscriptions_settings, :pager_enabled, :boolean, null: false, default: false
    add_column :subscriptions_settings, :cursor, :integer, null: false, default: 50
    add_column :subscriptions_settings, :cursor_enabled, :boolean, null: false, default: false
    add_column :subscriptions_settings, :products, :boolean, null: false, default: false
  end
end
