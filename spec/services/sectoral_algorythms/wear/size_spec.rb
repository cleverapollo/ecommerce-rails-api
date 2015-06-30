require 'rails_helper'

describe SectoralAlgorythms::Wear::Size do
  describe '.calculate_for' do
     let!(:shop) { create(:shop) }
     let!(:user) { create(:user) }

    context 'when cold' do
      let(:item) { create(:item, shop: shop, sizes:['e42', 'r44']) }

      subject { SectoralAlgorythms::Wear::Size.new(user).value }

      it 'returns user size' do
        expect(subject.keys).to eql(['m', 'f'])
      end
    end

    context 'when have views ' do
      subject { SectoralAlgorythms::Wear::Size.new(user).value }

      let(:male_small_items) { SizeHelper::SIZE_TYPES.map { |size_type| create(:item, shop: shop, sizes:['r42', 'e44',  'M', 'b5'], wear_type:size_type)} }
      let(:female_small_items) { SizeHelper::SIZE_TYPES.map { |size_type| create(:item, shop: shop, gender:'f', sizes:['r38', 'e36',  'M', 'b4'], wear_type:size_type)} }

      context 'when user small view' do
        subject {
          service = SectoralAlgorythms::Service.new(user, [SectoralAlgorythms::Wear::Size])
          # (SectoralAlgorythms::Wear::Size::MIN_VIEWS_SCORE*2)
              2.times { service.trigger_action(Actions::View.new, male_small_items) }
              2.times { service.trigger_action(Actions::View.new, female_small_items) }


          SectoralAlgorythms::Wear::Size.new(user).value
        }

        it 'returns size that user views most' do
          expect(subject['m']['shoe']['adult']['probability']).to be > 0
          expect(subject['f']['shoe']['adult']['probability']).to be > 0
        end
      end

      # context 'when user big purchase' do
      #   subject {
      #     service = SectoralAlgorythms::Service.new(user, [SectoralAlgorythms::Wear::Size])
      #     2.times { service.trigger_action(Actions::Purchase.new, [big_items]) }
      #
      #     service.trigger_action(Actions::View.new, [small_items])
      #
      #     SectoralAlgorythms::Wear::Size.new(user).value
      #   }
      #
      #   it 'returns size that user purchase most' do
      #     expect(subject[:probability]).to be > 0
      #   end
      # end



    end
  end
end
