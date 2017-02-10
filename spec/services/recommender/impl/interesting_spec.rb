require 'rails_helper'

describe Recommender::Impl::Interesting do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user, gender: 'm') }
  let!(:test_item) { create(:item, shop: shop, sales_rate: 10000, discount: true) }
  let!(:test_item_small_sr) { create(:item, shop: shop, sales_rate: 100) }

  10.times do |i|
    let!("user#{i}".to_sym) { create(:user) }
    let!("item#{i}".to_sym) { create(:item, shop: shop, sales_rate: rand(100..200), category_ids: "{1}") }
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 12, type: 'interesting') }

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
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end
      end
    end



    context 'when discount provided' do

      before { params[:discount] = true }

      it 'returns only discount item' do
        recommender = Recommender::Impl::Interesting.new(params)
        expect(recommender.recommendations).to include(test_item.uniqid)
        expect(recommender.recommendations.count).to eq 1
      end
    end


    context 'industrial' do

      context 'gender' do

        before { test_item.update is_fashion: true, fashion_gender: 'f' }

        it 'skips female products when client is male' do
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

      end


      context 'pets' do

        before {
          test_item.update is_pets: true, pets_type: 'dog', pets_breed: 'terrier'
        }

        it 'skips pet filter if user has no pets' do
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes dog product without breed' do
          user.update pets: [{'type' => 'dog', 'score' => 13}]
          test_item.update pets_breed: nil
          params.user = user
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes dog product with breed' do
          user.update pets: [{'type' => 'dog', 'breed' => 'terrier', 'score' => 13}]
          params.user = user
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'skips cat products' do
          user.update pets: [{'type' => 'cat', 'breed' => 'nordic', 'score' => 13}]
          params.user = user
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'skips dog products for wrong breed' do
          user.update pets: [{'type' => 'dog', 'breed' => 'bulldog', 'score' => 13}]
          params.user = user
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

      end


      context 'kids' do

        before {
          test_item.update is_child: true, child_gender: 'm', child_age_min: 1.0, child_age_max: 2.0
        }

        it 'skips kid filter if user has no kids' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes kid product without gender' do
          user.update children: [{'age_min' => 1.1, 'age_max' => 1.9}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes kid product without min age' do
          user.update children: [{'gender' => 'm', 'age_max' => 1.9}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes kid product without max age' do
          user.update children: [{'gender' => 'm', 'age_min' => 1.1}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'all kid data present' do
          user.update children: [{'gender' => 'm', 'age_min' => 1.1, 'age_max' => 1.9}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'all kid data present min age out of' do
          user.update children: [{'gender' => 'm', 'age_min' => 0.9, 'age_max' => 1.9}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'all kid data present max age out of' do
          user.update children: [{'gender' => 'm', 'age_min' => 1.1, 'age_max' => 2.1}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'all kid data present max and min age out of' do
          user.update children: [{'gender' => 'm', 'age_min' => 0.9, 'age_max' => 2.1}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'excludes by min age' do
          user.update children: [{'gender' => 'm', 'age_min' => 2.1, 'age_max' => 2.2}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'excludes by max age' do
          user.update children: [{'gender' => 'm', 'age_min' => 0.9, 'age_max' => 0.95}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'excludes by gender' do
          user.update children: [{'gender' => 'f', 'age_min' => 1.1, 'age_max' => 1.9}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end


        context 'product min or max age is null' do

          it 'min age is null' do
            user.update children: [{'gender' => 'm', 'age_min' => 1.1, 'age_max' => 1.9}]
            params.user = user
            test_item.update child_age_min: nil
            recommender = Recommender::Impl::Popular.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end
          it 'max age is null' do
            user.update children: [{'gender' => 'm', 'age_min' => 1.1, 'age_max' => 1.9}]
            params.user = user
            test_item.update child_age_max: nil
            recommender = Recommender::Impl::Popular.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end
        end

      end


    end


  end
end
