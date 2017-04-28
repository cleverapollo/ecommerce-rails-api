require 'rails_helper'

describe LocationsImportWorker do
  let!(:shop) { create(:shop) }

  it 'works with one location' do
    LocationsImportWorker.new.perform(shop.id, [{id: 1, name: 'Moscow', parent: nil}])
    expect(ShopLocation.first.external_id).to eq('1')
    expect(ShopLocation.first.name).to eq('Moscow')
  end

  it 'works with multiple locations and incorrect sort' do
    LocationsImportWorker.new.perform(shop.id, [{id: 2, name: 'Moscow', parent: 1}, {id: 1, name: 'Russia', parent: nil}])

    expect(ShopLocation.find_by(shop_id: shop.id, external_id: 1).present?).to be_truthy
    expect(ShopLocation.find_by(shop_id: shop.id, external_id: 1).name).to eq('Russia')

    expect(ShopLocation.find_by(shop_id: shop.id, external_id: 2).present?).to be_truthy
    expect(ShopLocation.find_by(shop_id: shop.id, external_id: 2).name).to eq('Moscow')
    expect(ShopLocation.find_by(shop_id: shop.id, external_id: 2).parent_external_id).to eq('1')
    expect(ShopLocation.find_by(shop_id: shop.id, external_id: 2).parent_id).to eq(ShopLocation.find_by(shop_id: shop.id, external_id: 1).id)
  end
end