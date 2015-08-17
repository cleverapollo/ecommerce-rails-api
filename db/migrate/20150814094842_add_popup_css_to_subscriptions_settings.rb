class AddPopupCssToSubscriptionsSettings < ActiveRecord::Migration
  def change
    add_column :subscriptions_settings, :css, :text

    SubscriptionsSettings.find_each do |settings|
      settings.update(css: settings.assign_default_css)
    end

  end
end
