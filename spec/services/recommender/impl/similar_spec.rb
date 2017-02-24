require 'rails_helper'

describe Recommender::Impl::Similar do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:test_item) { create(:item, shop: shop, price:550) }
  let!(:cheap_item) { create(:item, shop: shop, price:490) }

  5.times do |i|
    let!("user#{i}".to_sym) { create(:user) }
    let!("item#{i}".to_sym) { create(:item, shop: shop, price:i*200, location_ids: []) }
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 7, type:'similar', item: item2) }

  def create_action(user_data, item, is_buy = false)
    a = item.actions.new(user: user_data,
                         shop: shop,
                         timestamp: 1.day.ago.to_i,
                         rating: Actions::View::RATING)

    if is_buy
      a.purchase_count = 1
      a.rating = Actions::Purchase::RATING
    end
    a.save!
  end

  describe '#recommend' do
    before { create_action(user, item2, true) }
    before { create_action(user, item3, true) }

    before { create_action(user2, test_item, true) }
    before { create_action(user2, cheap_item, true) }
    before { create_action(user2, item2, true) }
    before { create_action(user2, item3, true) }

    before { create_action(user3, test_item, true) }
    before { create_action(user3, cheap_item, true) }
    before { create_action(user3, item2, true) }
    before { create_action(user3, item3, true) }
    before { create_action(user3, item4, true) }

    context 'when category not provided' do
      context 'when there is enough purchases' do
        it 'returns most similar items' do
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end
      end
    end


    context 'when category provided' do
      before { params[:categories] = test_item.category_ids }

      context 'when there is enough purchases' do
        it 'returns most similar items' do
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end
      end
    end



    context 'industrials' do

      # Тест на дочках показывает снижение продаж. Проверка.
      # context 'kids' do
      #
      #   before {
      #     item2.update is_child: true, child_gender: 'm', child_age_min: 1.1, child_age_max: 1.9
      #     test_item.update is_child: true, child_gender: 'm', child_age_min: 1.0, child_age_max: 2.0
      #   }
      #
      #   it 'includes item by kids param' do
      #     recommender = Recommender::Impl::Similar.new(params)
      #     expect(recommender.recommendations).to include(test_item.uniqid)
      #   end
      #
      #   it 'includes item by kids param if source item have no gender' do
      #     item2.update is_child: nil
      #     recommender = Recommender::Impl::Similar.new(params)
      #     expect(recommender.recommendations).to include(test_item.uniqid)
      #   end
      #
      #   it 'excludes item by kids param if recommended item have no gender' do
      #     test_item.update is_child: nil
      #     recommender = Recommender::Impl::Similar.new(params)
      #     expect(recommender.recommendations).to_not include(test_item.uniqid)
      #   end
      #
      #   it 'it excludes item by gender' do
      #     test_item.update is_child: 'f'
      #     recommender = Recommender::Impl::Similar.new(params)
      #     expect(recommender.recommendations).to_not include(test_item.uniqid)
      #   end
      #
      #   it 'excludes item by min age' do
      #     item2.update child_age_min: 2.1
      #     recommender = Recommender::Impl::Similar.new(params)
      #     expect(recommender.recommendations).to_not include(test_item.uniqid)
      #   end
      #
      #   it 'excludes item by max age' do
      #     item2.update child_age_max: 0.9
      #     recommender = Recommender::Impl::Similar.new(params)
      #     expect(recommender.recommendations).to_not include(test_item.uniqid)
      #   end
      #
      # end

      context 'jewelry' do

        before {
          test_item.update is_jewelry: true, jewelry_gem: 'diamond', jewelry_color: 'yellow', jewelry_metal: 'gold'
        }

        it 'includes item without data' do
          item2.update is_jewelry: true
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'excludes item with wrong gem' do
          item2.update is_jewelry: true, jewelry_gem: 'ruby'
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'excludes item with wrong metal' do
          item2.update is_jewelry: true, jewelry_color: 'white'
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'excludes item with wrong color' do
          item2.update is_jewelry: true, jewelry_metal: 'silver'
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'includes item with one fit' do
          item2.update is_jewelry: true, jewelry_gem: 'diamond', jewelry_color: '-', jewelry_metal: 'gold'
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          item2.update is_jewelry: true, jewelry_gem: '-', jewelry_color: 'yellow', jewelry_metal: 'gold'
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          item2.update is_jewelry: true, jewelry_gem: 'diamond', jewelry_color: 'yellow', jewelry_metal: '-'
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

      end

    end


  end
end
