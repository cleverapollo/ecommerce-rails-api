class FixOrdersDateIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_orders_on_shop_id_and_date'
    add_index "orders", ["shop_id", "date", :user_id], name: "index_orders_on_shop_id_and_date_and_user_id", algorithm: :concurrently
  end
  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_orders_on_shop_id_and_date_and_user_id'
    add_index "orders", ["shop_id", "date"], name: "index_orders_on_shop_id_and_date", algorithm: :concurrently
  end
end
