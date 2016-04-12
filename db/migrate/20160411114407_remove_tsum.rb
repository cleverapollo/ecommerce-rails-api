class RemoveTsum < ActiveRecord::Migration
  def change
    drop_table :tsum_segments
    drop_table :tsum_tracks
  end
end
