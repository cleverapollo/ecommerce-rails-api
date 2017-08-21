class FixPriceIndexOnItems < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_items_on_price'
    execute 'create index CONCURRENTLY index_items_on_price on items(shop_id, price) where ((is_available = true) AND (ignored = false) AND (price IS NOT NULL))'
  end
end
