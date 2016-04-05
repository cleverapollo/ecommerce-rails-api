class AddWithEmailToAudience < ActiveRecord::Migration
  def change
    add_column :audience_segment_statistics, :with_email, :integer, default: 0, null: false
  end
end
