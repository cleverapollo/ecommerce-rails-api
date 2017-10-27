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
    expect(@shop.items.count).to eq(1)
    @item = @shop.items.first
    expect(@item.uniqid).to eq('100')
    expect(@item.price.to_i).to eq(99)
    expect(@item.is_available).to eq(true)
    expect(@item.category_ids).to eq(['5'])

    # Action should be created
    expect(@user.actions.count).to eq(1)
    @action = @user.actions.first
    expect(@action.item_id).to eq(@item.id)
    expect(@action.rating).to eq(3.2)
    expect(@action.recommended_by).to eql('interesting')

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

    # Action should modyfied
    expect(@user.actions.count).to eq(1)
    @action = @user.actions.first
    expect(@action.item_id).to eq(@item.id)
    expect(@action.rating).to eq(4.2)
    expect(@action.recommended_by).to eql('interesting')

    Sidekiq::Testing.inline! do
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
