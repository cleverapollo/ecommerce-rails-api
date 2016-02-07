class AddItemIdToTsumTracks < ActiveRecord::Migration
  def change
    add_column :tsum_tracks, :item_uniqid, :string
  end
end
