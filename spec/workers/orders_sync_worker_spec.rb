require 'rails_helper'

describe OrdersSyncWorker do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:order) { create(:order, shop: shop, user: user, uniqid: '123') }
  let!(:params) {
    {
      'shop_id' => shop.uniqid, 'shop_secret' => shop.secret,

      'orders' => [
        {
          'id' => '123', 'status' => '1'
        }
      ]
    }
  }

  it 'persists given orders' do
    OrdersSyncWorker.new.perform(params)

    order = shop.orders.first!
    expect(order.uniqid).to eq( params['orders'][0]['id'] )
    expect(order.status).to eq( params['orders'][0]['status'].to_i )
    expect(order.status_date).to eq( Date.current )

  end
end
