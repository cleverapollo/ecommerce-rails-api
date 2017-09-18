class AddAutoIndexToItem < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    execute "CREATE INDEX CONCURRENTLY index_items_on_auto_compatibility ON items(((auto_compatibility->>'brands')::text), ((auto_compatibility->>'models')::text)) WHERE auto_compatibility IS NOT NULL AND is_auto = true AND is_available = true AND ignored = false AND widgetable = true"
  end

  def down
    execute 'DROP INDEX CONCURRENTLY IF EXISTS index_items_on_auto_compatibility'
  end
end
