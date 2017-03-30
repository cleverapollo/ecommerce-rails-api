class FixIndexesClientsDigests < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    remove_index :clients, name: 'index_clients_on_shop_id_and_digests_enabled'
    remove_index :clients, name: 'index_clients_on_shop_id_and_triggers_enabled'
    add_index :clients, [:id, :shop_id, :email, :digests_enabled], name: 'index_clients_on_shop_id_and_digests_enabled', where: 'email IS NOT NULL AND digests_enabled = true', algorithm: :concurrently
    add_index :clients, [:id, :shop_id, :email, :triggers_enabled], name: 'index_clients_on_shop_id_and_triggers_enabled', where: 'email IS NOT NULL AND triggers_enabled = true', algorithm: :concurrently
  end
  def down
    remove_index :clients, name: 'index_clients_on_shop_id_and_digests_enabled'
    remove_index :clients, name: 'index_clients_on_shop_id_and_triggers_enabled'
    add_index :clients, [:shop_id], name: 'index_clients_on_shop_id_and_digests_enabled', where: '((email IS NOT NULL) AND (digests_enabled IS TRUE))', algorithm: :concurrently
    add_index :clients, [:shop_id], name: 'index_clients_on_shop_id_and_triggers_enabled', where: '((email IS NOT NULL) AND (triggers_enabled IS TRUE))', algorithm: :concurrently
  end
end
