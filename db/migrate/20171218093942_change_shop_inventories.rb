class ChangeShopInventories < ActiveRecord::Migration
  def change
  	add_column :shop_inventories, :timeout, :integer
  	add_column :shop_inventories, :item_count, :integer
  	add_column :shop_inventories, :title, :string
  	add_column :shop_inventory_banners, :min_price, :decimal, null: false, default: 0.0
  	add_column :shop_inventory_banners, :currency_id, :integer
  	add_column :shop_inventory_banners, :prices, :jsonb
  end
end
