class IndexEmailConfirmed < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    add_index :clients, [:shop_id, :email_confirmed, :id], where: 'email IS NOT NULL', name: 'index_clients_on_shop_id_and_email_confirmed', algorithm: :concurrently
    DataManager::Partition::Client.partitions_size.times do |i|
      if ActiveRecord::Base.connection.table_exists?(DataManager::Partition::Client.table_name(i))
        add_index "clients_#{i}", [:shop_id, :email_confirmed, :id], where: 'email IS NOT NULL', name: "clients_#{i}_shop_id_email_confirmed_idx", algorithm: :concurrently
      end
    end
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id_and_email_confirmed'
    DataManager::Partition::Client.partitions_size.times do |i|
      execute "DROP INDEX CONCURRENTLY IF EXISTS clients_#{i}_shop_id_email_confirmed_idx"
    end
  end
end
