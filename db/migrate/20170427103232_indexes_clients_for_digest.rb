class IndexesClientsForDigest < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_digests_enabled'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_triggers_enabled'
    add_index 'clients', ['shop_id', 'email', 'digests_enabled', :id], name: 'index_clients_on_shop_id_and_digests_enabled', where: '((email IS NOT NULL) AND (digests_enabled = true))', using: :btree
    add_index 'clients', ['shop_id', 'email', 'triggers_enabled', :id], name: 'index_clients_on_shop_id_and_triggers_enabled', where: '((email IS NOT NULL) AND (triggers_enabled = true))', using: :btree
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_digests_enabled'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_triggers_enabled'
    add_index 'clients', [:id, 'shop_id', 'email', 'digests_enabled'], name: 'index_clients_on_shop_id_and_digests_enabled', where: '((email IS NOT NULL) AND (digests_enabled = true))', using: :btree
    add_index 'clients', [:id, 'shop_id', 'email', 'triggers_enabled'], name: 'index_clients_on_shop_id_and_triggers_enabled', where: '((email IS NOT NULL) AND (triggers_enabled = true))', using: :btree
  end
end
