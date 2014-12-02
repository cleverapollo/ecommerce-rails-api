class AddOpenedToTriggerMails < ActiveRecord::Migration
  def change
    add_column :trigger_mails, :opened, :boolean, null: false, default: false
  end
end
