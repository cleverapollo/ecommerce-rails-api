class CreateAudienceSegmentStatistics < ActiveRecord::Migration
  def change
    create_table :audience_segment_statistics do |t|
      t.references :shop
      t.integer :overall, default: 0, null: false
      t.integer :activity_a, default: 0, null: false
      t.integer :activity_b, default: 0, null: false
      t.integer :activity_c, default: 0, null: false
      t.date :recalculated_at, null: false
    end
    add_index :audience_segment_statistics, :shop_id, unique: true
  end
end
