class CreateClientCartIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_client_carts_on_shop_id'
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_client_carts_on_user_id'
    execute 'CREATE INDEX CONCURRENTLY index_client_carts_on_user_id ON client_carts(user_id)'

    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_search_queries_on_user_id'
    execute 'CREATE INDEX CONCURRENTLY index_search_queries_on_user_id ON search_queries(user_id)'
  end
  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_client_carts_on_user_id'
    add_index "client_carts", ["shop_id"], name: "index_client_carts_on_shop_id", using: :btree, algorithm: :concurrently
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_search_queries_on_user_id'
  end
end
