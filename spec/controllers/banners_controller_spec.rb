require 'rails_helper'

describe BannersController do
  let!(:rub) { create(:currency, code: 'rubT', exchange_rate: 1) }
  let!(:usd) { create(:currency, code: 'usdT', exchange_rate: 60) }
  let!(:vendor) { create(:vendor) }

  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:shop_inventory) { create(:shop_inventory, shop: shop, inventory_type: :banner, image_width: 100, image_height: 70, currency: rub) }
  let!(:shop_inventory_banner) { create(:shop_inventory_banner, shop_inventory: shop_inventory, min_price: 10) }

  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:client) { create(:client, session: session, shop: shop) }

  let(:params) { { shop_id: shop.uniqid, id: shop_inventory.id, ssid: session.code } }

  before { allow_any_instance_of(VendorCampaign).to receive(:available_for_client).and_return(true) }

  it 'without vendors' do
    get :get, params
    r = JSON.parse(response.body)
    expect(r['settings']['width']).to eq(100)
    expect(r['settings']['height']).to eq(70)
    expect(r['banners'].count).to eq(1)
    expect(r['banners'][0]['inventory']).to eq(shop_inventory.id)
    expect(r['banners'][0]['position']).to eq(shop_inventory_banner.position)
    expect(r['banners'][0]['id']).to be_nil
  end

  context 'with single vendor' do
    let!(:vendor_campaign) { create(:vendor_campaign, vendor: vendor, shop: shop, shop_inventory: shop_inventory, max_cpc_price: 1, currency: usd) }

    it 'works' do
      get :get, params
      r = JSON.parse(response.body)
      expect(r['banners'].count).to eq(1)
      expect(r['banners'][0]['id']).to eq(vendor_campaign.id)
    end

    it 'not vendor_campaign for price' do
      vendor_campaign.update(max_cpc_price: 0.1)

      get :get, params
      r = JSON.parse(response.body)
      expect(r['banners'].count).to eq(1)
      expect(r['banners'][0]['id']).to be_nil
    end
  end

  context 'with auction vendors' do
    let!(:vendor_campaign_1) { create(:vendor_campaign, vendor: vendor, shop: shop, shop_inventory: shop_inventory, max_cpc_price: 1, currency: usd) }
    let!(:vendor_campaign_2) { create(:vendor_campaign, vendor: create(:vendor), shop: shop, shop_inventory: shop_inventory, max_cpc_price: 9, currency: rub) }
    let!(:vendor_campaign_3) { create(:vendor_campaign, vendor: create(:vendor), shop: shop, shop_inventory: shop_inventory, max_cpc_price: 0.1, currency: usd) }

    it 'works' do
      get :get, params
      r = JSON.parse(response.body)
      expect(r['banners'].count).to eq(1)
      expect(r['banners'][0]['id']).to eq(vendor_campaign_1.id)
    end
  end

  context 'with double banners' do
    let!(:vendor_campaign_1) { create(:vendor_campaign, vendor: vendor, shop: shop, shop_inventory: shop_inventory, max_cpc_price: 1, currency: usd) }
    let!(:vendor_campaign_2) { create(:vendor_campaign, vendor: create(:vendor), shop: shop, shop_inventory: shop_inventory, max_cpc_price: 0.1, currency: usd) }
    let!(:vendor_campaign_3) { create(:vendor_campaign, vendor: create(:vendor), shop: shop, shop_inventory: shop_inventory, max_cpc_price: 9, currency: rub) }
    let!(:shop_inventory_banner_2) { create(:shop_inventory_banner, shop_inventory: shop_inventory, min_price: 9) }

    it 'works' do
      get :get, params
      r = JSON.parse(response.body)
      expect(r['banners'].count).to eq(2)
      expect(r['banners'][0]['id']).to eq(vendor_campaign_1.id)
      expect(r['banners'][1]['id']).to eq(vendor_campaign_3.id)
    end
  end

  context 'with vendor filter' do
    let!(:vendor_campaign) { create(:vendor_campaign, vendor: vendor, shop: shop, shop_inventory: shop_inventory, max_cpc_price: 1, currency: usd) }

    before { allow_any_instance_of(VendorCampaign).to receive(:available_for_client).and_return(false) }

    it 'works' do
      get :get, params
      r = JSON.parse(response.body)
      expect(r['banners'].count).to eq(1)
      expect(r['banners'][0]['id']).to be_nil
    end
  end

  context 'timed banner' do
    let!(:shop_inventory) { create(:shop_inventory, shop: shop, inventory_type: :banner, image_width: 100, image_height: 70, currency: rub, payment_type: PAYMENT_TYPES[:pph]) }


  end
end
