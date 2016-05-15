require 'rails_helper'

describe 'Pushing an event' do

  before do
    @shop = create(:shop)
    @user = create(:user)
    @session = create(:session, user: @user)
    @client = create(:client, shop: @shop, user: @user, supply_trigger_sent: true)

    @params = {
      event: 'view',
      shop_id: @shop.uniqid,
      ssid: @session.code,
      item_id: [39559, 15464],
      price: [14375, 25000],
      is_available: [1, 0],
      category: [191, 15],
      attributes: ['{"fashion":{"gender":"m","type":"shoe","sizes":["e39.5","e41","e41.5"],"brand":"ARTIOLI"}, "child":{"age":{"min":0.25, "max":1.25}}}'],
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
    @params[:user_email]='test@rees46demo.com'
    post '/push', @params

    expect(Action.all.map(&:rating)).to match_array([4.2, 4.2])
    expect { @user.clients.first.email = 'test@rees46demo.com' }

    @params[:event] = 'remove_from_cart'
    post '/push', @params

    expect(Action.all.map(&:rating)).to match_array([3.7, 3.7])
  end


  it 'clears supply_trigger_sent for client' do
    @params[:event] = 'purchase'
    @params[:amount] = [1,1]
    post '/push', @params
    expect(response.body).to eq({ status: 'success' }.to_json)
    expect(@client.reload.supply_trigger_sent).to eq(nil)
  end


end
