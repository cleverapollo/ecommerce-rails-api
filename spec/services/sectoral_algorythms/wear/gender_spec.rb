require 'rails_helper'

describe SectoralAlgorythms::Wear::Gender do
  describe '.calculate_for' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    context 'when current_item is passed' do
      let(:item_attributes) { { 'gender' => 'm' } }
      let(:item) { create(:item, shop: shop, custom_attributes: item_attributes) }

      subject { SectoralAlgorythms::Wear::Gender.calculate_for(user, shop: shop, current_item: item) }

      it 'returns current_item gender' do
        expect(subject).to eq(item.custom_attributes['gender'])
      end
    end
    context 'when current_item is not passed ' do
      subject { SectoralAlgorythms::Wear::Gender.calculate_for(user, shop: shop) }
      context 'when user has actions in shop' do
        let(:male_item_attributes) { { 'gender' => 'm' } }
        let(:male_item) { create(:item, shop: shop, custom_attributes: male_item_attributes) }
        let!(:male_item_action) { create(:action, user: user, shop: shop, item: male_item) }
        let(:female_item_attributes) { { 'gender' => 'f' } }
        let(:female_item_1) { create(:item, shop: shop, custom_attributes: female_item_attributes) }
        let!(:female_item_action_1) { create(:action, user: user, shop: shop, item: female_item_1) }
        let(:female_item_2) { create(:item, shop: shop, custom_attributes: female_item_attributes) }
        let!(:female_item_action_2) { create(:action, user: user, shop: shop, item: female_item_2) }

        it 'returns gender that user views most' do
          expect(subject).to eq('f')
        end
      end
      context 'when user has items in other shops' do
        let(:shop_2) { create(:shop) }
        let(:not_wear_item) { create(:item, shop: shop_2) }
        let!(:not_wear_item_action) { create(:action, user: user, shop: shop_2, item: not_wear_item) }

        let(:shop_3) { create(:shop) }
        let(:wear_item_attributes) { { 'gender' => 'f' } }
        let(:wear_item) { create(:item, shop: shop_3, custom_attributes: wear_item_attributes) }
        let!(:wear_item_action) { create(:action, user: user, shop: shop_3, item: wear_item) }

        it 'returns gender that user views most' do
          expect(subject).to eq('f')
        end
      end
      context 'when user hasnt actions in shop' do
        it 'returns random gender' do
          expect(%w(m f)).to include(subject)
        end
      end
    end
  end
end
