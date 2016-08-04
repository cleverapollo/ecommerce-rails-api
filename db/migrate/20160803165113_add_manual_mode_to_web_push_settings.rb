class AddManualModeToWebPushSettings < ActiveRecord::Migration
  def change
    add_column :web_push_subscriptions_settings, :manual_mode, :boolean, default: false
  end
end
