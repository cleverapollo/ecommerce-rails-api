class AddOrdersToShopMetric < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :orders_original_count, :integer, default: 0
    add_column :shop_metrics, :orders_original_revenue, :decimal, default: 0.0
    add_column :shop_metrics, :orders_recommended_count, :integer, default: 0
    add_column :shop_metrics, :orders_recommended_revenue, :decimal, default: 0.0
  end
end
