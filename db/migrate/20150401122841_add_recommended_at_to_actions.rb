class AddRecommendedAtToActions < ActiveRecord::Migration
  def change
    add_column :actions, :recommended_at, :timestamp
  end
end
