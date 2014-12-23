require 'rails_helper'

describe Item do
  describe '.fetch' do
    before {
      @shop = create(:shop)
    }
    subject { Item.fetch(@shop.id, @item_data) }

    context 'when item exsists' do
      before { @item_data = create(:item, shop: @shop) }
      it 'fetches that item' do
        expect(subject).to eq(@item_data)
      end
    end

    context 'when item not exsists' do
      before { @item_data = build(:item, shop: @shop) }

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
    let!(:item) { create(:item, shop: shop) }

    it 'disables the item' do
      item.disable!

      expect(item.is_available).to be_falsey
    end
  end
end
