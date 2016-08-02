class AddWebPushToAudienceSegment < ActiveRecord::Migration
  def change
    add_column :audience_segment_statistics, :web_push_overall, :integer, default: 0, null: false
  end
end
