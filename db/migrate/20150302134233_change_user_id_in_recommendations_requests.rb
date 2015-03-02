class ChangeUserIdInRecommendationsRequests < ActiveRecord::Migration
  def change
    change_column :recommendations_requests, :user_id, :integer, null: true
  end
end
