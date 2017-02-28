class AddRecommendationToShopMetrics < ActiveRecord::Migration
  def change
    add_column :shop_metrics, :recommendation_requests, :integer
  end
end
