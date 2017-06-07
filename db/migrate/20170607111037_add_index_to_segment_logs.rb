class AddIndexToSegmentLogs < ActiveRecord::Migration
  def change
    add_index :create_segment_changes_logs, [:label], where: ("label IS NOT NULL AND label != 'initial'")
  end
end
