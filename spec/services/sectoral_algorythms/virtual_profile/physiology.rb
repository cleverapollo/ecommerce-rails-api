require 'rails_helper'

describe SectoralAlgorythms::VirtualProfile::Physiology do
  describe '.calculate_for' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }

    context 'when cold' do
      let(:item) { create(:item, shop: shop, part_type: ['hair', 'face']) }

      subject { SectoralAlgorythms::VirtualProfile::Physiology.new(user).value }

      it 'returns user size' do
        expect(subject.keys).to eql(['m', 'f'])
      end
    end

    context 'when have views ' do
      subject { SectoralAlgorythms::VirtualProfile::Physiology.new(user).value }

      let(:male_items) { SectoralAlgorythms::VirtualProfile::Physiology::PART_TYPES.map { |part_type| create(:item, shop: shop, gender:'m', skin_type: ['dry', 'normal'], part_type: part_type) } }
      let(:female_small_items) { SectoralAlgorythms::VirtualProfile::Physiology::PART_TYPES.map { |part_type| create(:item, shop: shop, gender: 'f', skin_type: ['oily', 'comby'], part_type: part_type) } }

      context 'when user small view' do
        subject {
          service = SectoralAlgorythms::Service.new(user, [SectoralAlgorythms::VirtualProfile::Physiology])

          2.times { service.trigger_action('view', male_items) }
          2.times { service.trigger_action('view', female_items) }


          SectoralAlgorythms::VirtualProfile::Physiology.new(user).value
        }

        it 'returns size that user views most' do
          expect(subject['m']['hair']['dry']['probability']).to be > 0
          expect(subject['f']['hair']['oily']['probability']).to be > 0
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
