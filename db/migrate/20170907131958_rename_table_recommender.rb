class RenameTableRecommender < ActiveRecord::Migration
  def change
    rename_table :recommenders, :recommender_blocks
  end
end
