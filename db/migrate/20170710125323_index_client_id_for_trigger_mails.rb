class IndexClientIdForTriggerMails < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_trigger_mails_on_client_id'
    execute 'create index CONCURRENTLY index_trigger_mails_on_client_id ON trigger_mails(client_id);'
  end
  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_trigger_mails_on_client_id'
  end
end
