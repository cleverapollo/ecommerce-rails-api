class RenameBranchIdToCategoryIdInRecommendationsRequests < ActiveRecord::Migration
  def change
    rename_column :recommendations_requests, :branch_id, :category_id
  end
end
