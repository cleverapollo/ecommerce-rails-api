class AddIsTestRunningInToRecommenderBlocks < ActiveRecord::Migration
  def change
    add_column :recommender_blocks, :is_test_running, :boolean
    add_column :recommender_blocks, :draft_rules, :jsonb
    add_column :recommender_blocks, :test_started_at, :datetime
    add_column :recommender_blocks, :test_ended_at, :datetime
  end
end
