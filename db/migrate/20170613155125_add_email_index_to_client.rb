class AddEmailIndexToClient < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    add_index :clients, [:shop_id], name: 'index_client_on_shop_id_and_email_present', where: 'email IS NOT NULL', algorithm: :concurrently
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_client_on_shop_id_and_email_present'
  end
end
