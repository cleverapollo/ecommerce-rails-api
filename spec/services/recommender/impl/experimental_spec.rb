require 'rails_helper'

describe Recommender::Impl::Experiment do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:item1) { create(:item, shop: shop, sales_rate:2000) }

  10.times do |i|
    let!("user#{i}".to_sym) { create(:user) }
    let!("item#{i}".to_sym) { create(:item, shop: shop, sales_rate:rand(100..1000)) }
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 7, type:'experiment') }

  def create_action(item, is_buy = false)
    a = item.actions.new(user: other_user,
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
      before { params[:categories] = item1.categories }

      context 'when there is enough purchases' do
        before { create_action(item1, true) }

        it 'returns most frequently buyed items' do
          recommender = Recommender::Impl::Experiment.new(params)
          expect(recommender.recommendations).to include(item1.uniqid)
        end
      end
    end
  end
end
