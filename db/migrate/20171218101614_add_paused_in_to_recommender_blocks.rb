class AddPausedInToRecommenderBlocks < ActiveRecord::Migration
  def change
    add_column :recommender_blocks, :paused, :boolean, default: false
  end
end
