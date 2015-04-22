require 'rails_helper'

describe Item do
  let!(:shop) { create(:shop) }
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

  describe '.in_locations' do
    let!(:item1) { create(:item, shop: shop, locations: {'1' => { 'price' => 100 }}) }
    let!(:item2) { create(:item, shop: shop, locations: {'2' => { 'price' => 200 }}) }

    context 'when array is given' do
      it 'fetches items by elements' do
        expect(Item.in_locations(['1']).to_a).to match_array(item1)
      end
    end
    context 'when hash is given' do
      it 'fetches items by keys' do
        expect(Item.in_locations({'1' => {} }).to_a).to match_array(item1)
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

  describe '#price_in' do
    let(:item) { build(:item, shop: shop) }
    subject { item.price_in(argument) }

    context 'when nothing passed' do
      let(:argument) { nil }

      it 'returns base price' do
        expect(subject).to eq(item.price)
      end
    end
    context 'when location id is passed' do
      let(:argument) { '1' }

      context 'when location is available' do
        before { item.locations[argument] = {} }

        context 'when location has own price' do
          let(:location_price) { 100.0 }
          before { item.locations[argument] = { 'price' => location_price } }

          it 'returns location price' do
            expect(subject).to eq(location_price)
          end
        end
        context 'when location hasnt own price' do
          it 'returns base price' do
            expect(subject).to eq(item.price)
          end
        end
      end
      context 'when location isnt available' do
        it 'returns base price' do
          expect(subject).to eq(item.price)
        end
      end
    end
  end
end
