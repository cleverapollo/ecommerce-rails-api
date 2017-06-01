class FixItemIndexPrice < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_items_on_price'
    add_index :items, [:price, :shop_id], name: 'index_items_on_price', where: '((is_available = true) AND (ignored = false) AND (price IS NOT NULL))', using: :btree, algorithm: :concurrently
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_items_on_price'
    add_index :items, [:price], name: 'index_items_on_price', where: '((is_available = true) AND (ignored = false) AND (price IS NOT NULL))', using: :btree, algorithm: :concurrently
  end
end
