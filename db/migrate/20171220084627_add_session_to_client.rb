class AddSessionToClient < ActiveRecord::Migration
  def up
    add_column :clients, :session_id, :integer, limit: 8
    add_index :clients, [:session_id, :shop_id], unique: true, where: 'session_id IS NOT NULL'

    DataManager::Partition::Client.partitions_size.times do |i|
      if ActiveRecord::Base.connection.table_exists?(DataManager::Partition::Client.table_name(i))
        add_index DataManager::Partition::Client.table_name(i), [:session_id, :shop_id], unique: true, where: 'session_id IS NOT NULL', name: "#{DataManager::Partition::Client.table_name(i)}_session_id_shop_id_idx"
      end
    end

    add_column :orders, :client_id, :integer, limit: 8
    add_index :orders, :client_id, where: 'client_id IS NOT NULL'
  end

  def down
    remove_column :clients, :session_id
    remove_column :orders, :client_id
  end
end
