class RenameShopsUsersToClients < ActiveRecord::Migration
  def change
    rename_table :shops_users, :clients
    rename_column :digest_mails, :shops_user_id, :client_id
    rename_column :trigger_mails, :shops_user_id, :client_id
  end
end
