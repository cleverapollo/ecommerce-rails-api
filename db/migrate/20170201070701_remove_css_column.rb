class RemoveCssColumn < ActiveRecord::Migration
  def change
    remove_column :subscriptions_settings, :css
    remove_column :web_push_subscriptions_settings, :css
  end
end
