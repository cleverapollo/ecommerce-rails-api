require 'rails_helper'

describe CategoriesImportWorker do
  let!(:shop) { create(:shop) }
  before { allow(ErrorsMailer).to receive(:categories_import_error) {|shop, e| raise e} }

  it 'works with one location' do
    CategoriesImportWorker.new.perform(shop.id, JSON.parse([{id: 1, name: 'T-Shirt', parent: nil}].to_json))
    expect(ItemCategory.first.present?).to be_truthy
    expect(ItemCategory.first.external_id).to eq('1')
    expect(ItemCategory.first.name).to eq('T-Shirt')
  end

  it 'works with multiple locations and incorrect sort' do
    CategoriesImportWorker.new.perform(shop.id, JSON.parse([{id: 2, name: 'T-Shirt', parent: 1}, {id: 1, name: 'Sandaly', parent: nil}].to_json))

    expect(ItemCategory.find_by(shop_id: shop.id, external_id: 1).present?).to be_truthy
    expect(ItemCategory.find_by(shop_id: shop.id, external_id: 1).name).to eq('Sandaly')

    expect(ItemCategory.find_by(shop_id: shop.id, external_id: 2).present?).to be_truthy
    expect(ItemCategory.find_by(shop_id: shop.id, external_id: 2).name).to eq('T-Shirt')
    expect(ItemCategory.find_by(shop_id: shop.id, external_id: 2).parent_external_id).to eq('1')
    expect(ItemCategory.find_by(shop_id: shop.id, external_id: 2).parent_id).to eq(ItemCategory.find_by(shop_id: shop.id, external_id: 1).id)
  end
end
