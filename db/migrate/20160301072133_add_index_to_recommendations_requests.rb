class AddIndexToRecommendationsRequests < ActiveRecord::Migration
  def change
    add_index :recommendations_requests, :shop_id
  end
end
