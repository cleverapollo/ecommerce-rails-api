require 'spec_helper'

describe 'Order workflow' do
  before do
    @shop = create(:shop)
  end

  it 'performs workflow correctly' do
    # Init
    get 'init_script'

    # Session and user should be created
    expect(Session.count).to eq(1)
    expect(User.count).to eq(1)
    @session = Session.first
    @user = @session.user

    # First view of first item
    post 'push', {
      event: 'view',
      shop_id: @shop.uniqid,
      ssid: @session.uniqid,
      item_id: [100],
      price: [99],
      is_available: [1],
      category: [5],
      recommended_by: 'interesting'
    }

    # Item should be created
    expect(@shop.items.count).to eq(1)
    @item = @shop.items.first
    expect(@item.uniqid).to eq('100')
    expect(@item.price.to_i).to eq(99)
    expect(@item.is_available).to eq(true)
    expect(@item.category_uniqid).to eq('5')

    # Action should be created
    expect(@user.actions.count).to eq(1)
    @action = @user.actions.first
    expect(@action.item_id).to eq(@item.id)
    expect(@action.rating).to eq(3.2)
    expect(@action.price.to_i).to eq(99)
    expect(@action.is_available).to eq(true)
    expect(@action.category_uniqid).to eq('5')
    expect(@action.recommended_by).to eql('interesting')

    # Cart
    post 'push', {
      event: 'cart',
      shop_id: @shop.uniqid,
      ssid: @session.uniqid,
      item_id: [100],
      price: [99],
      is_available: [1],
      category: [5],
      recommended_by: 'interesting'
    }

    # Action should modyfied
    expect(@user.actions.count).to eq(1)
    @action = @user.actions.first
    expect(@action.item_id).to eq(@item.id)
    expect(@action.rating).to eq(4.2)
    expect(@action.price.to_i).to eq(99)
    expect(@action.is_available).to eq(true)
    expect(@action.category_uniqid).to eq('5')
    expect(@action.recommended_by).to eql('interesting')

    # Purchase
    post 'push', {
      event: 'purchase',
      shop_id: @shop.uniqid,
      ssid: @session.uniqid,
      order_id: 157,
      item_id: [100],
      amount: [1],
      user_id: '555'
    }

    # Session and user should be same count
    expect(Session.count).to eq(1)
    expect(User.count).to eq(1)

    # Action should modyfied
    expect(Action.count).to eq(1)
    @action = Action.first
    expect(@action.item_id).to eq(@item.id)
    expect(@action.rating).to eq(5)
    expect(@action.price.to_i).to eq(99)
    expect(@action.is_available).to eq(true)
    expect(@action.category_uniqid).to eq('5')
    expect(@action.recommended_by).to eql('interesting')

    # Order
    expect(Order.count).to eq(1)
    expect(OrderItem.first.recommended_by).to eq('interesting')
  end
end