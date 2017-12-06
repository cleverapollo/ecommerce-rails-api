require 'rails_helper'

describe Recommender::Impl::Popular do
  let!(:shop) { create(:shop, has_products_jewelry: true, has_products_kids: true, has_products_fashion: true, has_products_pets: true, has_products_cosmetic: true, has_products_fmcg: true, has_products_auto: true) }
  let!(:user) { create(:user, gender: 'm') }
  let!(:session) { create(:session, user: user) }
  let!(:other_user) { create(:user) }
  let!(:test_item) { create(:item, shop: shop, sales_rate: 10000, discount: true) }
  let!(:test_item_small_sr) { create(:item, shop: shop, sales_rate: 100) }

  10.times do |i|
    let!("user#{i}".to_sym) { u = create(:user); create(:session, user: u, code: SecureRandom.uuid); u }
    let!("item#{i}".to_sym) { create(:item, shop: shop, sales_rate: 100 + i * 10, category_ids: "{1}", price: 10 * i, uniqid: "id#{i * 100}") }
  end

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 7, type: 'popular') }

  describe '#recommend' do

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

    context 'when price_sensitive provided' do
      before {
        params[:price_sensitive] = 75
        params[:price_range] = 0.1
        params[:categories] = [1]
      }
      let!(:action1) { create(:action_cl, session: session, shop: shop, event: 'view', object_type: 'Item', object_id: item1.uniqid, price: 100) }
      let!(:action2) { create(:action_cl, session: session, shop: shop, event: 'view', object_type: 'Item', object_id: item2.uniqid, price: 50) }

      it 'returns items' do
        recommender = Recommender::Impl::Popular.new(params)
        expect(recommender.recommendations).to eq([item8.uniqid, item7.uniqid, item9.uniqid, item6.uniqid, item5.uniqid, item4.uniqid, item3.uniqid])
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


    context 'industrial' do

      context 'gender' do

        before { test_item.update is_fashion: true, fashion_gender: 'f' }

        it 'skips female products when client is male' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

      end


      context 'fashion_sizes' do

        context 'fit sizes' do
          before {
            test_item.update is_fashion: true, fashion_gender: 'f', fashion_wear_type: 'shoe', fashion_sizes: ['1', '2', '3', '4']
            user.update fashion_sizes: {shoe: ['1', '2']}, gender: 'f'
          }
          it 'includes product of correct size' do
            recommender = Recommender::Impl::Popular.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end

        end

        context 'not fit sizes' do
          before {
            test_item.update is_fashion: true, fashion_gender: 'f', fashion_wear_type: 'shoe', fashion_sizes: ['3', '4']
            user.update fashion_sizes: {shoe: ['1', '2']}, gender: 'f'
          }
          it 'skips female products of wrong size' do
            recommender = Recommender::Impl::Popular.new(params)
            expect(recommender.recommendations).to_not include(test_item.uniqid)
          end
        end

        context 'includes because data absent' do
          before {
            test_item.update is_fashion: true, fashion_gender: 'f', fashion_wear_type: 'shoe', fashion_sizes: ['3', '4']
            user.update fashion_sizes: {shoe: ['1', '2']}, gender: 'f'
          }
          it 'without wear type' do
            test_item.update fashion_wear_type: nil
            recommender = Recommender::Impl::Popular.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end
          it 'without wear gender' do
            test_item.update fashion_gender: nil
            recommender = Recommender::Impl::Popular.new(params)
            expect(recommender.recommendations).to include(test_item.uniqid)
          end
        end



      end



      context 'pets' do

        before {
          test_item.update is_pets: true, pets_type: 'dog', pets_breed: 'terrier'
        }

        it 'skips pet filter if user has no pets' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes dog product without breed' do
          user.update pets: [{'type' => 'dog', 'score' => 13}]
          test_item.update pets_breed: nil
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'includes dog product with breed' do
          user.update pets: [{'type' => 'dog', 'breed' => 'terrier', 'score' => 13}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'skips cat products' do
          user.update pets: [{'type' => 'cat', 'breed' => 'nordic', 'score' => 13}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'skips dog products for wrong breed' do
          user.update pets: [{'type' => 'dog', 'breed' => 'bulldog', 'score' => 13}]
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

      end




      context 'jewelry', :jewelry do

        before {
          test_item.update is_jewelry: true, jewelry_gender: 'f', jewelry_color: 'yellow', jewelry_metal: 'gold', jewelry_gem: 'ruby', ring_sizes: ['16', '17', '18'], bracelet_sizes: ['16', '17', '18'], chain_sizes: ['16', '17', '18']
        }

        it 'skips jewelry filter if user has no jewelry' do
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
        end

        it 'checks gender' do
          user.update jewelry: {'gender' => 'f'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          user.update jewelry: {'gender' => 'm'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'checks materials' do
          user.update jewelry: {'color' => 'yellow', 'metal' => 'silver', 'gem' => 'diamond'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          user.update jewelry: {'color' => 'white', 'metal' => 'gold', 'gem' => 'diamond'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          user.update jewelry: {'color' => 'white', 'metal' => 'silver', 'gem' => 'ruby'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          user.update jewelry: {'color' => 'white', 'metal' => 'silver', 'gem' => 'diamond'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'checks sizes' do
          user.update jewelry: {'ring_size' => '16', 'bracelet_size' => '-', 'chain_size' => '-'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          user.update jewelry: {'ring_size' => '-', 'bracelet_size' => '16', 'chain_size' => '-'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          user.update jewelry: {'ring_size' => '-', 'bracelet_size' => '-', 'chain_size' => '16'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          user.update jewelry: {'ring_size' => '16', 'bracelet_size' => '16', 'chain_size' => '16'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to include(test_item.uniqid)
          user.update jewelry: {'ring_size' => '15', 'bracelet_size' => '15', 'chain_size' => '15'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
          expect(recommender.recommendations).to_not include(test_item.uniqid)
        end

        it 'checks full profile' do
          user.update jewelry: {'ring_size' => '16', 'bracelet_size' => '17', 'chain_size' => '18', 'color' => 'yellow', 'metal' => 'silver', 'gem' => 'diamond', 'gender' => 'f'}
          params.user = user
          recommender = Recommender::Impl::Popular.new(params)
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
