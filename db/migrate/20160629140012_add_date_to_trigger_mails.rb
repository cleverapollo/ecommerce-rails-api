class AddDateToTriggerMails < ActiveRecord::Migration
  def change
    add_column :trigger_mails, :date, :date
    add_column :digest_mails, :date, :date
    add_index :trigger_mails, :date
    add_index :digest_mails, :date
    add_index :trigger_mails, [:date, :shop_id]
    add_index :digest_mails, [:date, :shop_id]
  end
end
