class RemoveClientShopIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_clients_on_shop_id'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS clients_0_shop_id_idx'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS clients_1_shop_id_idx'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS clients_2_shop_id_idx'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS clients_3_shop_id_idx'
  end

  def down
    add_index "clients", ["shop_id"], name: "index_clients_on_shop_id", algorithm: :concurrently
  end
end
