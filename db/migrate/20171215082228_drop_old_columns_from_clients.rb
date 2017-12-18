class DropOldColumnsFromClients < ActiveRecord::Migration
  def up
    remove_column :clients, :email_confirmed
    remove_column :clients, :digest_opened
    remove_column :clients, :digests_enabled
    remove_column :clients, :triggers_enabled
    remove_column :clients, :last_trigger_mail_sent_at

    DataManager::Partition::Client.partitions_size.times do |i|
      if ActiveRecord::Base.connection.table_exists?(DataManager::Partition::Client.table_name(i))
        remove_column DataManager::Partition::Client.table_name(i), :email_confirmed
        remove_column DataManager::Partition::Client.table_name(i), :digest_opened
        remove_column DataManager::Partition::Client.table_name(i), :digests_enabled
        remove_column DataManager::Partition::Client.table_name(i), :triggers_enabled
        remove_column DataManager::Partition::Client.table_name(i), :last_trigger_mail_sent_at
      end
    end
  end

  def down
    add_column :clients, :email_confirmed, :boolean
    add_column :clients, :digest_opened, :boolean
    add_column :clients, :digests_enabled, :boolean, null: false, default: true
    add_column :clients, :triggers_enabled, :boolean, null: false, default: true
    add_column :clients, :last_trigger_mail_sent_at, :datetime

    DataManager::Partition::Client.partitions_size.times do |i|
      if ActiveRecord::Base.connection.table_exists?(DataManager::Partition::Client.table_name(i))
        add_column DataManager::Partition::Client.table_name(i), :email_confirmed, :boolean
        add_column DataManager::Partition::Client.table_name(i), :digest_opened, :boolean
        add_column DataManager::Partition::Client.table_name(i), :digests_enabled, :boolean, null: false, default: true
        add_column DataManager::Partition::Client.table_name(i), :triggers_enabled, :boolean, null: false, default: true
        add_column DataManager::Partition::Client.table_name(i), :last_trigger_mail_sent_at, :datetime
      end
    end
  end
end
