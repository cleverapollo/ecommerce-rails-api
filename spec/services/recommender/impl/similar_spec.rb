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
      context 'kids' do

        before {
          item2.update is_child: true, child_gender: 'm', child_age_min: 1.1, child_age_max: 1.9
          test_item.update is_child: true, child_gender: 'm', child_age_min: 1.0, child_age_max: 2.0
        }

        it 'includes item by kids param' do
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes item by kids param if source item have no gender' do
          item2.update is_child: nil
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'excludes item by kids param if recommended item have no gender' do
          test_item.update is_child: nil
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'it excludes item by gender' do
          test_item.update is_child: 'f'
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'excludes item by min age' do
          item2.update child_age_min: 2.1
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'excludes item by max age' do
          item2.update child_age_max: 0.9
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

      end

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

      context 'cosmetic' do
        context 'perfume' do
          before {
            test_item.update is_cosmetic: true, cosmetic_perfume_aroma: 'citrus', cosmetic_perfume_family: 'woody'
          }
          it 'includes item without data' do
            item2.update is_cosmetic: true
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end

          it 'excludes item with wrong aroma' do
            item2.update is_cosmetic: true, cosmetic_perfume_aroma: 'woody'
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to_not include(test_item.uniqid)
          end

          it 'includes item with one fit' do
            item2.update is_cosmetic: true, cosmetic_perfume_aroma: 'citrus', cosmetic_perfume_family: 'woody'
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end
        end

        context 'nail' do
          before {
            test_item.update is_cosmetic: true, cosmetic_nail: true, cosmetic_nail_type: 'polish', cosmetic_nail_color: 'red'
          }
          it 'includes item without data' do
            item2.update is_cosmetic: true
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end

          it 'excludes item with wrong nail' do
            item2.update is_cosmetic: true, cosmetic_nail: true
            test_item.update cosmetic_nail: false
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to_not include(test_item.uniqid)
          end

          it 'excludes item with wrong nail type' do
            item2.update is_cosmetic: true, cosmetic_nail: true, cosmetic_nail_type: 'tool'
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to_not include(test_item.uniqid)
          end

          it 'excludes item with wrong nail polish color' do
            item2.update is_cosmetic: true, cosmetic_nail: true, cosmetic_nail_type: 'polish', cosmetic_nail_color: 'green'
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to_not include(test_item.uniqid)
          end

          it 'includes item with one fit' do
            item2.update is_cosmetic: true, cosmetic_nail: true
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
            item2.update is_cosmetic: true, cosmetic_nail: true, cosmetic_nail_type: 'polish'
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
            item2.update is_cosmetic: true, cosmetic_nail: true, cosmetic_nail_type: 'polish', cosmetic_nail_color: 'red'
            recommender = Recommender::Impl::Similar.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end
        end
      end



      context 'fashion'  do

        it 'shows apparel of same type and sizes and excludes apparel from same type and wrong size and does not exclude apparel another type and size' do
          test_item.update is_fashion: true, fashion_gender: 'm', fashion_wear_type: 'shoe', fashion_sizes: ['2'], category_ids: [1]
          item1.update is_fashion: true, fashion_gender: 'm', fashion_wear_type: 'shoe', fashion_sizes: ['1', '2', '3'], category_ids: [1]
          item2.update is_fashion: true, fashion_gender: 'm', fashion_wear_type: 'show', fashion_sizes: nil, category_ids: [1]
          item3.update is_fashion: true, fashion_gender: 'm', fashion_wear_type: 'shoe', fashion_sizes: ['1', '3'], category_ids: [1]
          item4.update is_fashion: true, fashion_gender: 'm', fashion_wear_type: 'coat', fashion_sizes: ['1', '3'], category_ids: [1]
          params[:item] = test_item
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(item1.uniqid)
          expect(recommender.recommendations).to include(item2.uniqid)
          expect(recommender.recommendations).to_not include(item3.uniqid)
          expect(recommender.recommendations).to include(item4.uniqid)
        end

      end



      context 'realty', :realty do

        it 'shows similar real estate according to type, action and final space' do
          test_item.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_final: 33
          item0.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_final: 34
          item1.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_min: 29, realty_space_max: 35
          item2.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_min: 30, realty_space_max: 34
          item3.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_final: 100
          item4.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'sell', realty_space_final: 33
          params[:item] = test_item
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(item0.uniqid)
          expect(recommender.recommendations).to include(item1.uniqid)
          expect(recommender.recommendations).to include(item2.uniqid)
          expect(recommender.recommendations).to_not include(item3.uniqid)
          expect(recommender.recommendations).to_not include(item4.uniqid)
        end

        it 'shows similar real estate according to type, action and min/max space', :realty_min_max do
          test_item.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_min: 27, realty_space_max: 40
          item0.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_final: 34
          item1.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_min: 29, realty_space_max: 35
          item2.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_min: 30, realty_space_max: 34
          item3.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'rent', realty_space_final: 100
          item4.update category_ids: [1], is_realty: true, realty_type: 'flat', realty_action: 'sell', realty_space_final: 33
          params[:item] = test_item
          recommender = Recommender::Impl::Similar.new(params)
          expect(recommender.recommendations).to include(item0.uniqid)
          expect(recommender.recommendations).to include(item1.uniqid)
          expect(recommender.recommendations).to include(item2.uniqid)
          expect(recommender.recommendations).to_not include(item3.uniqid)
          expect(recommender.recommendations).to_not include(item4.uniqid)
        end

      end

    end


  end
end
