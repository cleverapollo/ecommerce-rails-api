class AddProductsStatsToShopMetrics < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :top_products, :jsonb, array: true
    add_column :shop_metrics, :products_statistics, :jsonb
  end
end
