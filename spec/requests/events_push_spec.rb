require 'spec_helper'

describe 'Pushing an event' do
  before do
    @shop = create(:shop)
    @user = create(:user)
    @session = create(:session, user: @user)

    @params = {
      event: 'view',
      shop_id: @shop.uniqid,
      ssid: @session.uniqid,
      item_id: [39559, 15464],
      price: [14375, 25000],
      is_available: [1, 0],
      category: [191, 15],
      recommended_by: 'similar'
    }
  end

  it 'persists a new view event' do
    post 'push', @params

    expect(response.body).to eq({ status: 'success' }.to_json)

    @action = Action.first

    expect(@action.shop_id).to eq(@shop.id)
    expect(@action.user_id).to eq(@user.id)
    expect(@action.rating).to eq(3.2)
    expect(@action.recommended_by).to eq('similar')
    puts @action.inspect
  end
end