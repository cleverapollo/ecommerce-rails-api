class AddDealIdToBeaconMessages < ActiveRecord::Migration
  def change
    add_column :beacon_messages, :deal_id, :string
  end
end
