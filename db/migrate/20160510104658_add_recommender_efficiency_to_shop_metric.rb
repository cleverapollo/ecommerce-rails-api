class AddRecommenderEfficiencyToShopMetric < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :product_views_total, :integer, default: 0
    add_column :shop_metrics, :product_views_recommended, :integer, default: 0
  end
end
