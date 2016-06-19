require 'rails_helper'

describe Recommender::Impl::Popular do
  let!(:shop) { create(:shop, enabled_fashion: true) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:test_item) { create(:item, shop: shop, sales_rate: 10000, discount: true) }
  let!(:test_item_small_sr) { create(:item, shop: shop, sales_rate: 100) }

  10.times do |i|
    let!("user#{i}".to_sym) { create(:user) }
    let!("item#{i}".to_sym) { create(:item, shop: shop, sales_rate: rand(100..200), category_ids: "{1}") }
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 7, type: 'experiment') }

  def create_action(user_data, item, is_buy = false)
    a = item.actions.new(user: user_data,
                         shop: shop,
                         timestamp: 1.day.ago.to_i,
                         rating: Actions::View::RATING)

    if is_buy
      a.purchase_count = 1
      a.rating = Actions::Purchase::RATING
    end
    a.save
  end

  describe '#recommend' do
    before { create_action(user, item2, true) }
    before { create_action(user, item3, true) }

    before { create_action(user2, test_item, true) }
    before { create_action(user2, item2, true) }
    before { create_action(user2, item3, true) }

    before { create_action(user3, test_item, true) }
    before { create_action(user3, item2, true) }
    before { create_action(user3, item3, true) }
    before { create_action(user3, item4, true) }

    context 'when category not provided' do
      context 'when there is enough purchases' do
        it 'returns most frequently buyed items' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end
      end
    end


    context 'when category provided' do
      before { params[:categories] = test_item.category_ids }

      context 'when there is enough purchases' do
        it 'returns most frequently buyed items' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end
      end

    end


    context 'when discount provided' do

      before { params[:discount] = true }

      it 'returns only discount item' do
        recommender = Recommender::Impl::Popular.new(params)
        expect(recommender.recommendations).to include(test_item.uniqid)
        expect(recommender.recommendations.count).to eq 1
      end
    end


  end
end
