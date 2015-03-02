require 'rails_helper'

describe 'Pushing an event' do
  before do
    @shop = create(:shop)
    @user = create(:user)
    @session = create(:session, user: @user)

    @params = {
      event: 'view',
      shop_id: @shop.uniqid,
      ssid: @session.code,
      item_id: [39559, 15464],
      price: [14375, 25000],
      is_available: [1, 0],
      category: [191, 15],
      attributes: ['{"gender":"m","type":"shoe","sizes":["e39.5","e41","e41.5"],"brand":"ARTIOLI"}'],
      recommended_by: 'similar'
    }
  end

  it 'persists a new view event' do
    post '/push', @params

    expect(response.body).to eq({ status: 'success' }.to_json)

    @action = Action.first

    expect(@action.shop_id).to eq(@shop.id)
    expect(@action.user_id).to eq(@user.id)
    expect(@action.rating).to eq(3.2)
    expect(@action.recommended_by).to eq('similar')

    item = Item.first!
    expect(item.custom_attributes).to eq({"gender" => "m","type" => "shoe","sizes" => ["e39.5","e41","e41.5"],"brand" => "ARTIOLI"})
  end

  it 'updates view event to cart' do
    post '/push', @params

    @params[:event] = 'cart'

    expect(Action.all.map(&:rating)).to match_array([3.2, 3.2])

    post '/push', @params

    expect(Action.count).to eq(2)

    @action = Action.last

    expect(Action.all.map(&:rating)).to match_array([4.2, 4.2])

    expect(@action.shop_id).to eq(@shop.id)
    expect(@action.user_id).to eq(@user.id)
    expect(@action.rating).to eq(4.2)
    expect(@action.last_action).to eq(2)
    expect(@action.recommended_by).to eq('similar')

    @params[:event] = 'view'
    post '/push', @params

    expect(Action.all.map(&:rating)).to match_array([4.2, 4.2])

    @params[:event] = 'remove_from_cart'
    post '/push', @params

    expect(Action.all.map(&:rating)).to match_array([3.7, 3.7])
  end
end
