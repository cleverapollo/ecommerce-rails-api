class FixTriggerMailingIndexes < ActiveRecord::Migration
  def up
    remove_index :trigger_mails, name: 'index_trigger_mails_on_shop_id_and_trigger_mailing_id'
    add_index :trigger_mails, [:shop_id, :trigger_mailing_id, :opened], name: 'index_trigger_mails_on_shop_id_and_trigger_mailing_id', using: :btree
  end

  def down
    remove_index :trigger_mails, name: 'index_trigger_mails_on_shop_id_and_trigger_mailing_id'
    add_index :trigger_mails, [:shop_id, :trigger_mailing_id], name: 'index_trigger_mails_on_shop_id_and_trigger_mailing_id', where: '(opened = false)', using: :btree
  end
end
