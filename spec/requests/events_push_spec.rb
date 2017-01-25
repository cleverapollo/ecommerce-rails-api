require 'rails_helper'

describe 'Pushing an event' do

  before do
    @shop = create(:shop)
    @user = create(:user)
    @session = create(:session, user: @user, code: SecureRandom.uuid)
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

  context 'default' do

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


  describe 'cart' do

    context 'track cart and correct events' do

      it 'saves client carts' do
        @params[:event] = 'cart'
        post '/push', @params
        expect(@user.reload.client_carts.count).to eq 1
      end

      it 'changes clients cart on remove from cart event' do

      end

      it 'changes clients cart on adding new product to cart' do

      end

    end

  end


  describe 'remove from cart' do

    let(:client_cart) { create(:client_cart, user: user, shop: shop, items: [1,2]) }

    it 'changes cart' do
      @params[:event] = 'cart'
      post '/push', @params
      expect(@user.reload.client_carts.first.items.sort).to eq Item.where(uniqid: @params[:item_id]).map(&:id).sort
    end

    it 'deletes empty cart' do
      @params[:event] = 'cart'
      @params[:item_id] = []
      post '/push', @params
      expect(@user.reload.client_carts.count).to eq 0
    end

  end


end
