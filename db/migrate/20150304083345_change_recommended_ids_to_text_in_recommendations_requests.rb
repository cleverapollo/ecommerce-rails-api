class ChangeRecommendedIdsToTextInRecommendationsRequests < ActiveRecord::Migration
  def change
    change_column :recommendations_requests, :recommended_ids, :text, array: true, default: [], null: false
  end
end
