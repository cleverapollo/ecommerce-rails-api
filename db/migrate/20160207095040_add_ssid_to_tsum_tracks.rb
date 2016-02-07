class AddSsidToTsumTracks < ActiveRecord::Migration
  def change
    add_column :tsum_tracks, :ssid, :string
  end
end
