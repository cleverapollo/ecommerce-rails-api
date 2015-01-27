class AddShopsUserIdToTriggerMails < ActiveRecord::Migration
  def change
    TriggerMail.delete_all

    add_column :trigger_mails, :shops_user_id, :integer, null: false
  end
end
