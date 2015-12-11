require 'rails_helper'

describe Item do
  let!(:shop) { create(:shop) }

  describe ".in_categories" do
    let!(:a)   { create(:item, shop_id: shop.id, category_ids: [1,2]) }
    let!(:b)   { create(:item, shop_id: shop.id, category_ids: [2,3]) }

    it { expect(shop.items.in_categories([1], { any: true }).pluck(:id)).to match_array([a.id]) }
    it { expect(shop.items.in_categories([2], { any: true }).pluck(:id)).to match_array([a.id, b.id]) }
    it { expect(shop.items.in_categories([3], { any: true }).pluck(:id)).to match_array([b.id]) }

    it { expect(shop.items.in_categories([1], { any: false }).pluck(:id)).to match_array([a.id]) }
    it { expect(shop.items.in_categories([2], { any: false }).pluck(:id)).to match_array([a.id, b.id]) }
    it { expect(shop.items.in_categories([3], { any: false }).pluck(:id)).to match_array([b.id]) }
  end

  describe ".in_locations" do
    let!(:a)   { create(:item, shop_id: shop.id, location_ids: [1,2]) }
    let!(:b)   { create(:item, shop_id: shop.id, location_ids: [2,3]) }

    it { expect(shop.items.in_locations([1], { any: true }).pluck(:id)).to match_array([a.id]) }
    it { expect(shop.items.in_locations([2], { any: true }).pluck(:id)).to match_array([a.id, b.id]) }
    it { expect(shop.items.in_locations([3], { any: true }).pluck(:id)).to match_array([b.id]) }

    it { expect(shop.items.in_locations([1], { any: false }).pluck(:id)).to match_array([a.id]) }
    it { expect(shop.items.in_locations([2], { any: false }).pluck(:id)).to match_array([a.id, b.id]) }
    it { expect(shop.items.in_locations([3], { any: false }).pluck(:id)).to match_array([b.id]) }
  end

  describe '.fetch' do
    subject { Item.fetch(shop.id, @item_data) }

    context 'when item exsists' do
      before { @item_data = create(:item, shop: shop) }

      it 'fetches that item' do
        expect(subject).to eq(@item_data)
      end
    end

    context 'when item not exsists' do
      before { @item_data = build(:item, shop: shop) }

      it 'creates an item' do
        expect{subject}.to change(Item, :count).from(0).to(1)
      end

      it 'stores item uniqid' do
        expect(subject.uniqid).to eq(@item_data.uniqid)
      end
    end
  end

  describe '#disable!' do
    let(:shop) { create(:shop) }
    let!(:item) { create(:item, shop: shop, widgetable: true) }

    it 'disables the item' do
      item.disable!

      expect(item.is_available).to be_falsey
      expect(item.widgetable).to be_falsey
    end
  end
end
