class AddTrackedToBeaconMessages < ActiveRecord::Migration
  def change
    add_column :beacon_messages, :tracked, :boolean, default: false, null: false
  end
end
