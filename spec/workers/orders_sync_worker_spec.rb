require 'rails_helper'

describe OrdersSyncWorker do
  let!(:customer) { create(:customer, balance: 100) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:user) { create(:user) }
  let!(:order) { create(:order, shop: shop, user: user, uniqid: '123', date: 1.day.ago, value: 100, source_type: 'TriggerMail') }
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

  it 'compensates fee for old orders' do
    params['orders'][0]['status'] = Order::STATUS_CANCELLED
    expect(order.refundable?).to be_truthy
    OrdersSyncWorker.new.perform(params)
    order = shop.orders.first!
    customer.reload
    expect(order.status).to eq( Order::STATUS_CANCELLED )
    expect(order.compensated).to be_truthy
    expect(order.refundable?).to be_falsey
    expect(customer.balance).to eq( 104 )
  end

  it 'does not compensate very old orders' do
    params['orders'][0]['status'] = Order::STATUS_CANCELLED
    order.update! date: 2.months.ago
    expect(order.refundable?).to be_falsey
    OrdersSyncWorker.new.perform(params)
    order = shop.orders.first!
    customer.reload
    expect(order.status).to eq( Order::STATUS_CANCELLED )
    expect(order.compensated).to be_falsey
    expect(order.refundable?).to be_falsey
    expect(customer.balance).to eq( 100 )
  end

  it 'does not compensate very new orders' do
    params['orders'][0]['status'] = Order::STATUS_CANCELLED
    order.update! date: DateTime.current
    expect(order.refundable?).to be_falsey
    OrdersSyncWorker.new.perform(params)
    order = shop.orders.first!
    customer.reload
    expect(order.status).to eq( Order::STATUS_CANCELLED )
    expect(order.compensated).to be_falsey
    expect(order.refundable?).to be_falsey
    expect(customer.balance).to eq( 100 )
  end

  it 'saves last orders sync date' do
    expect(shop.last_orders_sync).to eq nil
    OrdersSyncWorker.new.perform(params)
    expect(shop.reload.last_orders_sync).to_not eq nil
  end

end
