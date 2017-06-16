class FixTriggerMailIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_trigger_mails_on_trigger_mailing_id'
    add_index :trigger_mails, [:trigger_mailing_id, :date], name: 'index_trigger_mails_on_trigger_mailing_id', using: :btree
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_trigger_mails_on_trigger_mailing_id'
    add_index "trigger_mails", ["trigger_mailing_id"], name: "index_trigger_mails_on_trigger_mailing_id", using: :btree
  end
end
