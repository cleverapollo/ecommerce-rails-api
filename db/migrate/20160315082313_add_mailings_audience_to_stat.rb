class AddMailingsAudienceToStat < ActiveRecord::Migration
  def change
    add_column :audience_segment_statistics, :triggers_overall, :integer, default: 0, null: false
    add_column :audience_segment_statistics, :triggers_activity_a, :integer, default: 0, null: false
    add_column :audience_segment_statistics, :triggers_activity_b, :integer, default: 0, null: false
    add_column :audience_segment_statistics, :triggers_activity_c, :integer, default: 0, null: false
    add_column :audience_segment_statistics, :digests_overall, :integer, default: 0, null: false
    add_column :audience_segment_statistics, :digests_activity_a, :integer, default: 0, null: false
    add_column :audience_segment_statistics, :digests_activity_b, :integer, default: 0, null: false
    add_column :audience_segment_statistics, :digests_activity_c, :integer, default: 0, null: false
  end
end
