require 'rails_helper'

describe Recommender::Impl::Experiment do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:test_item) { create(:item, shop: shop, sales_rate:10000) }

  5.times do |i|
    let!("user#{i}".to_sym) { create(:user) }
    let!("item#{i}".to_sym) { create(:item, shop: shop, sales_rate:rand(100..200), categories:"{1}") }
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 7, type:'experiment') }

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
    context 'when category provided' do
      before { params[:categories] = test_item.categories }

      context 'when there is enough purchases' do
        before { create_action(user, item2, true) }
        before { create_action(user, item3, true) }

        before { create_action(user2, item2, true) }
        before { create_action(user2, item3, true) }
        before { create_action(user2, item1, true) }

        before { create_action(user3, item2, true) }
        before { create_action(user3, item3, true) }
        before { create_action(user3, item1, true) }
        before { create_action(user3, item4, true) }



        it 'returns most frequently buyed items' do
          recommender = Recommender::Impl::Experiment.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end
      end
    end
  end
end
