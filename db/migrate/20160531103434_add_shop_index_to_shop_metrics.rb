class AddShopIndexToShopMetrics < ActiveRecord::Migration
  def change
    add_index :shop_metrics, :shop_id
  end
end
