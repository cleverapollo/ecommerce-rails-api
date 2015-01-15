class MergeSubscriptionsIntoShopsUsers < ActiveRecord::Migration
  def change
    add_column :shops_users, :subscription_popup_showed, :boolean, default: false, null: false
    add_column :shops_users, :triggers_enabled, :boolean, null: false, default: true
    add_column :shops_users, :last_trigger_mail_sent_at, :timestamp
  end
end
