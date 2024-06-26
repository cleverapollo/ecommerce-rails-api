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
    let!(:item1) { create(:item, shop: @shop, uniqid: '39559') }
    let!(:item2) { create(:item, shop: @shop, uniqid: '15464') }
    let!(:item3) { create(:item, shop: @shop, uniqid: '1') }
    let(:clickhouse_queue) { ClickhouseQueue }

    it 'persists a new view event' do
      expect(clickhouse_queue).to receive(:actions).with(hash_including(event: 'view', recommended_by: 'similar')).twice

      post '/push', @params

      expect(response.body).to eq({ status: 'success' }.to_json)

    end

    it 'persists a new cart event' do
      @params[:event] = 'cart'

      expect(clickhouse_queue).to receive(:actions).with(hash_including(event: 'cart', recommended_by: 'similar')).twice

      post '/push', @params

      expect(response.body).to eq({ status: 'success' }.to_json)

    end

    it 'persists a new remove_from_cart event' do
      @params[:event] = 'remove_from_cart'

      expect(clickhouse_queue).to receive(:actions).with(hash_including(event: 'remove_from_cart', recommended_by: 'similar')).twice

      post '/push', @params

      expect(response.body).to eq({ status: 'success' }.to_json)

    end

    it 'bulk cart add' do
      @params[:event] = 'cart'
      @params[:item_id] = [39559, 15464]
      ClientCart.create!(shop: @shop, user: @user, items: [item2.id, item3.id])
      expect(clickhouse_queue).to receive(:actions).with(hash_including(event: 'cart', object_id: '39559')).once
      expect(clickhouse_queue).to receive(:actions).with(hash_including(event: 'remove_from_cart', object_id: '1')).once

      post '/push', @params

      expect(response.body).to eq({ status: 'success' }.to_json)
    end

    it 'bulk cart only remove' do
      @params[:event] = 'cart'
      @params[:item_id] = nil
      ClientCart.create!(shop: @shop, user: @user, items: [item2.id])

      expect(clickhouse_queue).to receive(:actions).with(hash_including(event: 'remove_from_cart', object_id: item2.uniqid)).once

      post '/push', @params

      expect(response.body).to eq({ status: 'success' }.to_json)
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
