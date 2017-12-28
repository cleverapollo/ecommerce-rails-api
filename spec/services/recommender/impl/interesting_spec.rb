require 'rails_helper'

describe Recommender::Impl::Interesting do
  let!(:shop) { create(:shop, has_products_jewelry: true, has_products_kids: true, has_products_fashion: true, has_products_pets: true, has_products_cosmetic: true, has_products_fmcg: true, has_products_auto: true) }
  let!(:user) { create(:user) }
  let!(:test_item) { create(:item, shop: shop, sales_rate: 10000, discount: true) }
  let!(:test_item_small_sr) { create(:item, shop: shop, sales_rate: 100) }

  10.times do |i|
    let!("user#{i}".to_sym) { create(:user) }
    let!("item#{i}".to_sym) { create(:item, shop: shop, sales_rate: rand(100..200), category_ids: "{1}") }
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 12, type: 'interesting', profile: People::Profile.new(gender: 'm')) }


  describe '#recommend' do


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
          params.profile = People::Profile.new(pets: [{'type' => 'dog', 'score' => 13}])
          test_item.update pets_breed: nil
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes dog product with breed' do
          params.profile = People::Profile.new(pets: [{'type' => 'dog', 'breed' => 'terrier', 'score' => 13}])
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'skips cat products' do
          params.profile = People::Profile.new(pets: [{'type' => 'cat', 'breed' => 'nordic', 'score' => 13}])
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'skips dog products for wrong breed' do
          params.profile = People::Profile.new(pets: [{'type' => 'dog', 'breed' => 'bulldog', 'score' => 13}])
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

      end


      context 'jewelry', :jewelry do

        before {
          test_item.update is_jewelry: true, jewelry_gender: 'f', jewelry_color: 'yellow', jewelry_metal: 'gold', jewelry_gem: 'ruby', ring_sizes: ['16', '17', '18'], bracelet_sizes: ['16', '17', '18'], chain_sizes: ['16', '17', '18']
        }

        it 'skips jewelry filter if user has no jewelry' do
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'checks gender' do
          params.profile = People::Profile.new(jewelry: {'gender' => 'f'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          params.profile = People::Profile.new(jewelry: {'gender' => 'm'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'checks materials' do
          params.profile = People::Profile.new(jewelry: {'color' => 'yellow', 'metal' => 'silver', 'gem' => 'diamond'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          params.profile = People::Profile.new(jewelry: {'color' => 'white', 'metal' => 'gold', 'gem' => 'diamond'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          params.profile = People::Profile.new(jewelry: {'color' => 'white', 'metal' => 'silver', 'gem' => 'ruby'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          params.profile = People::Profile.new(jewelry: {'color' => 'white', 'metal' => 'silver', 'gem' => 'diamond'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'checks sizes' do
          params.profile = People::Profile.new(jewelry: {'ring_size' => '16', 'bracelet_size' => '-', 'chain_size' => '-'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          params.profile = People::Profile.new(jewelry: {'ring_size' => '-', 'bracelet_size' => '16', 'chain_size' => '-'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          params.profile = People::Profile.new(jewelry: {'ring_size' => '-', 'bracelet_size' => '-', 'chain_size' => '16'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          params.profile = People::Profile.new(jewelry: {'ring_size' => '16', 'bracelet_size' => '16', 'chain_size' => '16'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          params.profile = People::Profile.new(jewelry: {'ring_size' => '15', 'bracelet_size' => '15', 'chain_size' => '15'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'checks full profile' do
          params.profile = People::Profile.new(jewelry: {'ring_size' => '16', 'bracelet_size' => '17', 'chain_size' => '18', 'color' => 'yellow', 'metal' => 'silver', 'gem' => 'diamond', 'gender' => 'f'})
          recommender = Recommender::Impl::Interesting.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
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
          params.profile = People::Profile.new(children: [{'age_min' => 1.1, 'age_max' => 1.9}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes kid product without min age' do
          params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_max' => 1.9}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes kid product without max age' do
          params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 1.1}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'all kid data present' do
          params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 1.1, 'age_max' => 1.9}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'all kid data present min age out of' do
          params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 0.9, 'age_max' => 1.9}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'all kid data present max age out of' do
          params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 1.1, 'age_max' => 2.1}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'all kid data present max and min age out of' do
          params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 0.9, 'age_max' => 2.1}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'excludes by min age' do
          params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 2.1, 'age_max' => 2.2}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'excludes by max age' do
          params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 0.9, 'age_max' => 0.95}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'excludes by gender' do
          params.profile = People::Profile.new(children: [{'gender' => 'f', 'age_min' => 1.1, 'age_max' => 1.9}])
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end


        context 'product min or max age is null' do

          it 'min age is null' do
            params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 1.1, 'age_max' => 1.9}])
            test_item.update child_age_min: nil
            recommender = Recommender::Impl::Popular.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end
          it 'max age is null' do
            params.profile = People::Profile.new(children: [{'gender' => 'm', 'age_min' => 1.1, 'age_max' => 1.9}])
            test_item.update child_age_max: nil
            recommender = Recommender::Impl::Popular.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end
        end

      end


    end


  end
end
