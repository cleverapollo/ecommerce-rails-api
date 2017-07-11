class FixClientIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_last_activity_at'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS idx_clients_shop_id_last_trigger_email_nulls_first'
    add_index :clients, [:shop_id, :last_activity_at, :last_trigger_mail_sent_at], name: 'index_clients_on_shop_id_and_last_activity_at', where: '(email IS NOT NULL AND triggers_enabled = true AND last_activity_at IS NOT NULL)', algorithm: :concurrently
  end
  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_last_activity_at'
    add_index "clients", ["shop_id", "last_activity_at"], name: "index_clients_on_shop_id_and_last_activity_at", where: "((email IS NOT NULL) AND (triggers_enabled IS TRUE) AND (last_activity_at IS NOT NULL))", algorithm: :concurrently
    add_index "clients", ["shop_id", "last_trigger_mail_sent_at"], name: "idx_clients_shop_id_last_trigger_email_nulls_first", where: "((triggers_enabled = true) AND (email IS NOT NULL))", using: :btree
  end
end
