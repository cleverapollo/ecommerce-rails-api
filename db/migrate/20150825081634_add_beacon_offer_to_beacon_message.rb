class AddBeaconOfferToBeaconMessage < ActiveRecord::Migration
  def change
    add_column :beacon_messages, :beacon_offer_id, :integer
    BeaconMessage.find_each do |bm|
      bm.update beacon_offer_id: 1
    end
  end
end
