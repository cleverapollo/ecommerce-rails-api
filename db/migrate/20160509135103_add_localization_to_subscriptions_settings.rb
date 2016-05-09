class AddLocalizationToSubscriptionsSettings < ActiveRecord::Migration
  def change
    add_column :subscriptions_settings, :button, :string
    add_column :subscriptions_settings, :agreement, :text
  end
end
