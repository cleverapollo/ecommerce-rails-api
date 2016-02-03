class CreateTsumTracks < ActiveRecord::Migration
  def change
    create_table :tsum_tracks do |t|
      t.string :engine
      t.string :block
      t.timestamps null: false
    end
    add_index :tsum_tracks, [:engine]
    add_index :tsum_tracks, [:engine, :block]
    add_index :tsum_tracks, [:engine, :created_at]
  end
end
