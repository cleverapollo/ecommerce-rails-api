class AddStrictRecommendationsToShops < ActiveRecord::Migration
  def change
    add_column :shops, :strict_recommendations, :boolean, default: false, null: false
  end
end
