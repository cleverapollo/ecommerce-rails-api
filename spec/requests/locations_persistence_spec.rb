require 'rails_helper'

describe 'Persisting locations info' do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:locations) { { '1' => { 'price' => 100 }, '2' => { } } }
  let!(:item) { create(:item, shop: shop, locations: locations) }
  let!(:params) { {
      event: 'view',
      shop_id: shop.uniqid,
      ssid: session.code,
      item_id: [item.uniqid],
      price: [item.price],
      is_available: [1],
      locations: ['1,3']
  
    }
  }

  it 'changes locations appropriately on push' do
    post '/push', params

    expect(Item.first!.locations).to eq(locations.tap{|l| l.delete('2') }.merge({ '3' => {}}))
  end
end
