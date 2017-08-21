class AddUnsubscribedToTriggerMail < ActiveRecord::Migration
  def change
    add_column :trigger_mails, :unsubscribed, :boolean
    add_column :digest_mails, :unsubscribed, :boolean
  end
end
