require 'rails_helper'

describe SectoralAlgorythms::Wear::Gender do
  describe '.calculate_for' do
     let!(:shop) { create(:shop) }
     let!(:user) { create(:user) }

    context 'when cold' do
      let(:item) { create(:item, shop: shop, gender:'m') }

      subject { SectoralAlgorythms::Wear::Gender.new(user).value }

      it 'returns current_item gender' do
        expect(subject).not_to be_empty
      end

      it 'returns random gender' do
        expect([:m, :f]).to eq(subject.keys)
      end
    end
    context 'when has info' do
      subject { SectoralAlgorythms::Wear::Gender.new(user).value }

      context 'when user male view' do
        let(:male_item) { create(:item, shop: shop, gender: 'm') }
        let(:female_item) { create(:item, shop: shop, gender: 'f') }


        subject {
          service = SectoralAlgorythms::Service.new(user, [SectoralAlgorythms::Wear::Gender])
          (SectoralAlgorythms::Wear::Gender::MIN_VIEWS_SCORE*2).times { service.trigger_action(Actions::View.new, [male_item]) }

          SectoralAlgorythms::Wear::Gender.new(user).value
        }

        it 'returns gender that user views most' do
          expect(subject[:m]).to be > subject[:f]
        end
      end

      context 'when user female purchase' do
        let(:male_item) { create(:item, shop: shop, gender: 'm') }
        let(:female_item) { create(:item, shop: shop, gender: 'f') }


        subject {
          service = SectoralAlgorythms::Service.new(user, [SectoralAlgorythms::Wear::Gender])
          service.trigger_action(Actions::Purchase.new, [female_item])

          SectoralAlgorythms::Wear::Gender.new(user).value
        }

        it 'returns gender that user purchase most' do
          expect(subject[:f]).to be > subject[:m]
        end
      end
    end
  end
end
