class FixWebPushIndexesFromClients < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_web_push_enabled'
    add_index "clients", ["shop_id", "last_web_push_sent_at", :id], name: "index_clients_on_shop_id_and_web_push_enabled", where: "(web_push_enabled = true)", algorithm: :concurrently

    DataManager::Partition::Client.partitions_size.times do |i|
      if ActiveRecord::Base.connection.table_exists?(DataManager::Partition::Client.table_name(i))
        execute "DROP INDEX CONCURRENTLY IF EXISTS clients_#{i}_shop_id_web_push_enabled_idx"
        execute "CREATE INDEX CONCURRENTLY clients_#{i}_shop_id_web_push_enabled_idx ON clients_#{i} (shop_id, last_web_push_sent_at, id asc) WHERE web_push_enabled = true"
      end
    end
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_web_push_enabled'
    add_index "clients", ["shop_id", "last_web_push_sent_at"], name: "index_clients_on_shop_id_and_web_push_enabled", where: "(web_push_enabled = true)", algorithm: :concurrently
  end
end
