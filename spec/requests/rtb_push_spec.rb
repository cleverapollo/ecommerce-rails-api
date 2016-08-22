require 'rails_helper'

describe 'Pushing an event for rtb' do

  before do
    @customer = create(:customer, balance: 300)
    @shop = create(:shop, customer: @customer, remarketing_enabled: true)
    @user = create(:user)
    @session = create(:session, user: @user)
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

  it 'creates one rtb job' do
    post '/push', @params
    expect(response.body).to eq({ status: 'success' }.to_json)
    rtb_jobs = RtbJob.all
    expect(rtb_jobs.count).to eq(1)
    expect(rtb_jobs.first.item_id).to eq(@item1.id)
    expect(rtb_jobs.first.shop_id).to eq(@shop.id)
    expect(rtb_jobs.first.user_id).to eq(@user.id)
  end


  it 'erases specific job after removed from cart' do
    params2 = @params
    params2[:is_available] = [1,1,1,1]
    post '/push', @params
    expect(response.body).to eq({ status: 'success' }.to_json)
    rtb_jobs = RtbJob.all
    expect(rtb_jobs.count).to eq(2)

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
    rtb_jobs = RtbJob.active
    expect(rtb_jobs.count).to eq(1)

  end


  it 'erases specific job after purchase' do
    params2 = @params
    params2[:is_available] = [1,1,1,1]
    post '/push', @params
    expect(response.body).to eq({ status: 'success' }.to_json)
    rtb_jobs = RtbJob.active
    expect(rtb_jobs.count).to eq(2)

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
    rtb_jobs = RtbJob.active
    expect(rtb_jobs.count).to eq(0)
  end


end
