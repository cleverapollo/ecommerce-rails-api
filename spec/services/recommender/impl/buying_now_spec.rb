require 'rails_helper'

describe Recommender::Impl::BuyingNow do
  let!(:shop) { create(:shop, has_products_jewelry: true, has_products_kids: true, has_products_fashion: true, has_products_pets: true, has_products_cosmetic: true, has_products_fmcg: true, has_products_auto: true) }
  let!(:user) { create(:user, gender: 'm') }
  let!(:session) { create(:session, user: user) }
  let!(:other_user) { create(:user) }
  let!(:test_item) { create(:item, shop: shop, sales_rate: 10000, discount: true) }
  let!(:test_item_small_sr) { create(:item, shop: shop, sales_rate: 100) }

  10.times do |i|
    let!("user#{i}".to_sym) { u = create(:user); create(:session, user: u, code: "s#{i}"); u }
    let!("item#{i}".to_sym) { create(:item, shop: shop, sales_rate: rand(100..200), category_ids: "{1}") }
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 7, type: 'buying_now') }

  def create_action(user_data, item, is_buy = false)
    ActionCl.create!(shop: shop, session: user_data.sessions.first, current_session_code: SecureRandom.uuid, event: is_buy ? 'purchase' : 'cart', object_type: 'Item', object_id: item.uniqid, useragent: 'test', referer: 'test', date: 1.day.ago.to_date, created_at: 1.day.ago)
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
          recommender = Recommender::Impl::BuyingNow.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end
      end
    end


    context 'when category provided' do
      before { params[:categories] = test_item.category_ids }

      context 'when there is enough purchases' do
        it 'returns most frequently buyed items' do
          recommender = Recommender::Impl::BuyingNow.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end
      end

    end


    context 'when discount provided' do

      before { params[:discount] = true }

      it 'returns only discount item' do
        recommender = Recommender::Impl::BuyingNow.new(params)
        expect(recommender.recommendations).to include(test_item.uniqid)
        expect(recommender.recommendations.count).to eq 1
      end
    end


    context 'industrial' do

      context 'gender' do

        before { test_item.update is_fashion: true, fashion_gender: 'f' }

        it 'applies gender filter' do
          recommender = Recommender::Impl::BuyingNow.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

      end

    end


  end
end
