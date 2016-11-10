class AddActivitySegmentColumns < ActiveRecord::Migration
  def change
    add_column :audience_segment_statistics, :with_email_activity_a, :integer, null: false, default: 0
    add_column :audience_segment_statistics, :with_email_activity_b, :integer, null: false, default: 0
    add_column :audience_segment_statistics, :with_email_activity_c, :integer, null: false, default: 0
    add_column :audience_segment_statistics, :web_push_activity_a, :integer, null: false, default: 0
    add_column :audience_segment_statistics, :web_push_activity_b, :integer, null: false, default: 0
    add_column :audience_segment_statistics, :web_push_activity_c, :integer, null: false, default: 0
  end
end
