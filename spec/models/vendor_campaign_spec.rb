require 'rails_helper'

RSpec.describe VendorCampaign, type: :model do

  let!(:rub) { create(:currency, code: 'rubT', exchange_rate: 1) }
  let!(:usd) { create(:currency, code: 'usdT', exchange_rate: 60) }
  let!(:vendor) { create(:vendor) }

  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:shop_inventory) { create(:shop_inventory, shop: shop, inventory_type: :banner, image_width: 100, image_height: 70, currency: rub) }
  let!(:shop_inventory_banner) { create(:shop_inventory_banner, shop_inventory: shop_inventory, min_price: 10) }
  let!(:vendor_campaign) { create(:vendor_campaign, vendor: vendor, shop: shop, shop_inventory: shop_inventory, max_cpc_price: 1, currency: usd) }

  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:client) { create(:client, session: session, shop: shop) }
  let!(:profile) { People::Profile.new }

  before { allow(client).to receive(:profile).and_return(profile) }

  context 'available_for_client' do

    it 'gender blank' do
      vendor_campaign.update(filters: {demography: {gender: 'm'}})
      expect(vendor_campaign.available_for_client(client)).to be_truthy
    end

    it 'gender equal' do
      vendor_campaign.update(filters: {demography: {gender: 'm'}})
      allow(client).to receive(:profile).and_return(People::Profile.new(gender: 'm'))

      expect(vendor_campaign.available_for_client(client)).to be_truthy
    end

    it 'gender not equal' do
      vendor_campaign.update(filters: {demography: {gender: 'm'}})
      allow(client).to receive(:profile).and_return(People::Profile.new(gender: 'f'))

      expect(vendor_campaign.available_for_client(client)).to be_falsey
    end

  end
end
