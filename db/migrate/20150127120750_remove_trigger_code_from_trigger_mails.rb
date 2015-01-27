class RemoveTriggerCodeFromTriggerMails < ActiveRecord::Migration
  def change
    remove_column :trigger_mails, :trigger_code
  end
end
