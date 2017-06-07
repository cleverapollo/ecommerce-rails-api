class CreateCreateSegmentChangesLogs < ActiveRecord::Migration
  def change
    create_table :create_segment_changes_logs do |t|
      t.integer :session_id, limit: 8, null: false
      t.string :ssid
      t.string :segment
      t.string :segment_previous
      t.string :page
      t.string :user_agent
      t.string :label
      t.timestamps null: false
    end
  end
end
