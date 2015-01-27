class RemoveSubscriptionIdFromTriggerMails < ActiveRecord::Migration
  def change
    remove_column :trigger_mails, :subscription_id, :integer, null: false
  end
end
