require 'spec_helper'

describe Recommender::Impl::Popular do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:item1) { create(:item, shop: shop) }
  let!(:params) { OpenStruct.new(shop: shop, user: user) }

  def create_action(item, is_buy = false)
    a = item.actions.new(user: other_user, 
                         shop: shop,
                         is_available: true,
                         timestamp: 1.day.ago.to_i,
                         rating: Actions::View::RATING)

    if is_buy
      a.purchase_count = 1
      a.rating = Actions::Purchase::RATING
    end
    a.save
  end

  describe '#items_to_weight' do
    context 'when category provided' do
      before { params[:categories] = item1.categories }

      context 'when there is enough purchases' do
        before { create_action(item1, true) }

        it 'returns most frequently buyed items' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.items_to_weight).to include(item1.id)
        end
      end

      context 'when there is not enough purchases' do
        before { create_action(item1) }

        it 'returns items by rating' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.items_to_weight).to include(item1.id)
        end
      end
    end

    context 'when no category provided' do
      context 'when there is enough purchases' do
        before { create_action(item1, true) }

        it 'returns most frequently buyed items' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.items_to_weight).to include(item1.id)
        end
      end

      context 'when there is not enough purchases' do
        before { create_action(item1) }

        it 'returns items by rating' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.items_to_weight).to include(item1.id)
        end
      end
    end
  end
end
