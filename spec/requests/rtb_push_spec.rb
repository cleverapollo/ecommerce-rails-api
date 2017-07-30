require 'rails_helper'
describe 'Pushing an event for rtb' do

  before do
    @currency = create(:currency, remarketing_min_price: 150.0, code: 'usd')
    @customer = create(:customer, balance: 300, currency: @currency)
    @shop = create(:shop, customer: @customer, remarketing_enabled: true, currency_code: 'usd', active: true, connected: true, restricted: false, logo: fixture_file_upload(Rails.root.join('spec/fixtures/files/rees46.png'), 'image/png'))
    @user = create(:user)
    @session = create(:session, user: @user, code: SecureRandom.uuid)
    @client = create(:client, shop: @shop, user: @user, supply_trigger_sent: true)
    @item1 = create(:item, shop: @shop, uniqid: '39559', widgetable: true, name: '123', url: 'http://ya.ru', image_url: 'http://ya.ru')
    @item2 = create(:item, shop: @shop, uniqid: '15464', widgetable: true, name: '123', url: 'http://ya.ru', image_url: 'http://ya.ru')
    @item3 = create(:item, shop: @shop, uniqid: '15467', widgetable: false, name: nil, url: 'http://ya.ru', image_url: 'http://ya.ru')
    @item4 = create(:item, shop: @shop, uniqid: '15460', widgetable: true, name: '123', url: 'http://ya.ru', image_url: 'http://ya.ru')

    @params = {
        event: 'cart',
        shop_id: @shop.uniqid,
        ssid: @session.code,
        item_id: [39559, 15464, 15467, 15460],
        price: [14375, 100, 10000, 10000],
        is_available: [1, 1, 1, 0],
        category: [191, 15, 1, 1],
    }
  end

  context 'Default' do

    it 'creates one rtb job' do
      post '/push', @params
      expect(response.body).to eq({ status: 'success' }.to_json)
      rtb_jobs = RtbJob.where(user_id: @user.id)
      expect(rtb_jobs.count).to eq(1)
      expect(rtb_jobs.first.shop_id).to eq(@shop.id)
      expect(rtb_jobs.first.user_id).to eq(@user.id)
      expect(rtb_jobs.first.logo).to eq(@shop.fetch_logo_url)
      expect(rtb_jobs.first.products.count).to eq(1)
      expect(rtb_jobs.first.products.first['id']).to eq @item1.id

      from_redis = JSON.parse(Redis.rtb.get("RMRK:#{@user.id}:#{@shop.id}"))
      expect(from_redis['id']).to eq rtb_jobs.first.id
      expect(from_redis['logo']).to eq rtb_jobs.first.logo
      expect(from_redis['url']).to eq rtb_jobs.first.url
      expect(from_redis['products']).to eq rtb_jobs.first.products
      expect(from_redis['currency']).to eq rtb_jobs.first.currency
      expect(from_redis['shop_id']).to eq @shop.id
      expect(from_redis['user_id']).to eq @user.id

    end


    it 'erases specific job after removed from cart' do
      params2 = @params
      params2[:is_available] = [1,1,1,1]
      post '/push', @params
      expect(response.body).to eq({ status: 'success' }.to_json)
      rtb_jobs = RtbJob.where(user_id: @user.id)
      expect(rtb_jobs.count).to eq(1)

      params2 = {
          event: 'remove_from_cart',
          shop_id: @shop.uniqid,
          ssid: @session.code,
          item_id: [39559],
          price: [14375],
          is_available: [1],
          categories: [191]
      }
      post '/push', params2
      expect(response.body).to eq({ status: 'success' }.to_json)
      rtb_jobs = RtbJob.active_for_user(@user)
      expect(rtb_jobs.count).to eq(1)

    end


    it 'erases specific job after purchase' do
      params2 = @params
      params2[:is_available] = [1,1,1,1]
      post '/push', @params
      expect(response.body).to eq({ status: 'success' }.to_json)
      rtb_jobs = RtbJob.active_for_user(@user)
      expect(rtb_jobs.count).to eq(1)

      params2 = {
          event: 'purchase',
          shop_id: @shop.uniqid,
          ssid: @session.code,
          item_id: [39559],
          price: [14375],
          is_available: [1],
          categories: [191]
      }
      post '/push', params2
      expect(response.body).to eq({ status: 'success' }.to_json)
      rtb_jobs = RtbJob.active_for_user(@user)
      expect(rtb_jobs.count).to eq(0)
    end

  end


end
