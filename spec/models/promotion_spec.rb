require 'rails_helper'

describe Promotion do
  let!(:shop) { create(:shop) }
  let!(:promotion) { create(:promotion) }

  it 'has a valid factory' do
    expect(promotion).to be_valid
  end

  describe '#show?' do
    let!(:item_category_1) { create(:item_category, shop: shop, external_id: '1', name: 'планшеты') }
    let!(:item_category_2) { create(:item_category, shop: shop, external_id: '2', name: 'рыбы') }

    context 'when categories passed' do
      it 'returns true if categories include promoted categories' do
        expect(promotion.show?(shop: shop, categories: ['1'])).to eq(true)
      end

      it 'returns false if categories doesnt include promoted categories' do
        expect(promotion.show?(shop: shop, categories: ['2'])).to eq(false)
      end
    end

    context 'when item passed' do
      it 'returns true if item categories include promoted categories' do
        item = double('item', categories: ['1', '2', '3'])

        expect(promotion.show?(shop: shop, item: item)).to eq(true)
      end

      it 'returns false if item categories doesnt include promoted categories' do
        item = double('item', categories: ['5'])

        expect(promotion.show?(shop: shop, item: item)).to eq(false)
      end
    end
  end

  describe '#scope' do
    let!(:item_1) { create(:item, shop: shop, name: 'apple iphone 6', brand:'apple') }
    let!(:item_2) { create(:item, shop: shop, name: 'huawei', brand:'huawei') }

    it 'scopes items by name' do
      expect(promotion.scope(shop.items).to_a).to match_array([item_1])
    end
  end
end
