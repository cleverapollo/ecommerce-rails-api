class AddSuccessfullyToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions_settings, :successfully, :text
    add_column :web_push_subscriptions_settings, :successfully, :text
  end
end
