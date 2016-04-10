require 'rails_helper'

describe SectoralAlgorythms::VirtualProfile::Size do
  describe '.calculate_for' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:size_user) { create(:user) }

    context 'when cold' do
      let(:item) { create(:item, shop: shop, fashion_sizes: ['e42', 'r44']) }

      subject { SectoralAlgorythms::VirtualProfile::Size.new(user.profile).value }

      it 'returns user size' do
        expect(subject.keys).to eql([:m, :f])
      end
    end

    context 'when have views ' do
      subject { SectoralAlgorythms::VirtualProfile::Size.new(user.profile).value }

      let(:male_small_items) { SizeHelper::SIZE_TYPES.map { |size_type| create(:item, shop: shop, fashion_sizes: ['r42', 'e44', 'M', 'b5'], fashion_wear_type: size_type) } }
      let(:male_small_items_size) { SizeHelper::SIZE_TYPES.map { |size_type| create(:item, shop: shop, fashion_gender: 'm', fashion_sizes: ['42', '44'], fashion_wear_type: size_type) } }
      let!(:male_small_items_size_50) { SizeHelper::SIZE_TYPES.map { |size_type| create(:item, shop: shop, fashion_gender: 'm', fashion_sizes: ['50', '52'], fashion_wear_type: size_type) } }
      let(:female_small_items) { SizeHelper::SIZE_TYPES.map { |size_type| create(:item, shop: shop, fashion_gender: 'f', fashion_sizes: ['r38', 'e36', 'M', 'b4'], fashion_wear_type: size_type) } }

      context 'when user small view' do
        subject {
          service = SectoralAlgorythms::Service.new(user, [SectoralAlgorythms::VirtualProfile::Size])
          # (SectoralAlgorythms::Wear::Size::MIN_VIEWS_SCORE*2)
          2.times { service.trigger_action('view', male_small_items) }
          2.times { service.trigger_action('view', female_small_items) }

          SectoralAlgorythms::VirtualProfile::Size.new(user.profile).value
        }

        it 'returns size that user views most' do
          expect(subject[:m]['shoe']['adult']['probability']).to be > 0
          expect(subject[:f]['shoe']['adult']['probability']).to be > 0
        end
      end

      context 'modify relation' do
        subject {
          service = SectoralAlgorythms::Service.new(size_user, [SectoralAlgorythms::VirtualProfile::Size, SectoralAlgorythms::VirtualProfile::Gender])
          # (SectoralAlgorythms::Wear::Size::MIN_VIEWS_SCORE*2)
          5.times { service.trigger_action('view', male_small_items_size) }
        }

        it 'correctly modify by type_size' do
          subject
          algo = SectoralAlgorythms::VirtualProfile::Size.new(size_user.profile)
          expect(algo.modify_relation_with_rollback(Item.where(fashion_gender:'m')).pluck(:fashion_sizes).flatten.uniq).not_to include('50', '52')
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
