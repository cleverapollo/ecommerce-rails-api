require 'rails_helper'

describe 'Order workflow' do
  before do
    @customer = create(:customer)
    @shop = create(:shop, customer: @customer)
    @trigger_mail = create(:trigger_mail, shop: @shop, client_id: 1, trigger_mailing_id: 1).reload
  end

  it 'performs workflow correctly' do
    # Init
    get '/init_script', shop_id: @shop.uniqid

    # Session and user should be created
    expect(Session.count).to eq(1)
    expect(User.count).to eq(1)
    @session = Session.first
    @user = @session.user

    expect(ClickhouseQueue).to receive(:actions).with(hash_including(event: 'view', object_id: '100', recommended_by: 'interesting'))

    # First view of first item
    post '/push', {
      event: 'view',
      shop_id: @shop.uniqid,
      ssid: @session.code,
      item_id: [100],
      price: [99],
      is_available: [1],
      categories: ['5'],
      recommended_by: 'interesting',
      source: { 'from' => 'trigger_mail', 'code' => @trigger_mail.code }.to_json
    }

    # Item should be created
    @item = @shop.items.first
    expect(@item.uniqid).to eq('100')
    expect(@item.price.to_i).to eq(99)
    expect(@item.is_available).to eq(true)
    expect(@item.category_ids).to eq(['5'])

    expect(ClickhouseQueue).to receive(:actions).with(hash_including(event: 'cart', object_id: '100', recommended_by: 'interesting'))

    # Cart
    post '/push', {
      event: 'cart',
      shop_id: @shop.uniqid,
      ssid: @session.code,
      item_id: [100],
      price: [99],
      is_available: [1],
      categories: ['5'],
      recommended_by: 'interesting',
      source: { 'from' => 'trigger_mail', 'code' => @trigger_mail.code }.to_json
    }

    Sidekiq::Testing.inline! do

      expect(ClickhouseQueue).to receive(:actions).with(hash_including(event: 'purchase', object_id: '100', recommended_by: nil))

      # Purchase
      post '/push', {
        event: 'purchase',
        shop_id: @shop.uniqid,
        ssid: @session.code,
        order_id: 157,
        item_id: [100],
        amount: [1],
        user_id: '555',
        source: { 'from' => 'trigger_mail', 'code' => @trigger_mail.code }.to_json
      }
    end

    # Session and user should be same count
    expect(Session.count).to eq(1)
    expect(User.count).to eq(1)

    # Order
    expect(Order.count).to eq(1)
    expect(OrderItem.first.recommended_by).to eq('trigger_mail')
    expect(Order.first.source).to eq(@trigger_mail)
  end
end
