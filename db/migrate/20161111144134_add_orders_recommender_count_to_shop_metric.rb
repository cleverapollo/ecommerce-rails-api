class AddOrdersRecommenderCountToShopMetric < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :orders_with_recommender_count, :integer, default: 0, null: false
  end
end
