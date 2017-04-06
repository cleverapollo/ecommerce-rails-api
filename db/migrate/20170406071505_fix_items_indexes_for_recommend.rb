class FixItemsIndexesForRecommend < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    remove_index :items, name: 'shop_available_index'
    add_index :items, [:shop_id, :is_available, :ignored, :id], where: 'is_available = true AND ignored = false', name: 'shop_available_index', algorithm: :concurrently
    add_index :items, [:shop_id, :brand, :id], where: 'is_available = true AND ignored = false AND widgetable = true AND (brand IS NOT NULL)', name: 'index_items_on_shop_and_brand', algorithm: :concurrently
  end

  def down
    remove_index :items, name: 'shop_available_index'
    add_index :items, [:shop_id, :is_available, :ignored], where: 'is_available = true AND ignored = false', name: 'shop_available_index', algorithm: :concurrently
    remove_index :items, name: 'index_items_on_shop_and_brand'
  end
end
