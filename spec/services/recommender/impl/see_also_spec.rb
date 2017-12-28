require 'rails_helper'

describe Recommender::Impl::SeeAlso do
  let!(:shop) { create(:shop, has_products_jewelry: true, has_products_kids: true, has_products_fashion: true, has_products_pets: true, has_products_cosmetic: true, has_products_fmcg: true, has_products_auto: true) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:item1) { create(:item, shop: shop, category_ids: '{3}') }
  let!(:item2) { create(:item, shop: shop, category_ids: '{3,5}') }
  let!(:item3) { create(:item, shop: shop, category_ids: '{7}') }
  let!(:item4) { create(:item, shop: shop, category_ids: '{12}') }
  let!(:profile) { People::Profile.new(children: [{'gender' => 'm'}]) }

  describe '#recommendations' do
    it 'returns ids of also bought items' do
      order = build(:order, shop: shop, user: other_user)

      [item1, item2, item3].each do |i|
        order.order_items.build(item: i, action_id: 123, shop_id: shop.id)
      end

      order.save!

      params = OpenStruct.new(
          shop: shop,
          user: user,
          item: item1,
          cart_item_ids: [item2.id],
          locations: [],
          limit:7,
          type: 'also_bought',
          skip_niche_algorithms: false,
      )

      recommender = Recommender::Impl::SeeAlso.new(params)

      result = recommender.recommendations

      expect(result).to include(item3.uniqid)
    end

    it 'shop_recommend' do
      order = build(:order, shop: shop, user: other_user)
      [item1, item2, item3].each do |i|
        order.order_items.build(item: i, action_id: 123, shop_id: shop.id)
      end
      order.save!

      params = OpenStruct.new(
          shop: shop,
          user: user,
          item: item1,
          cart_item_ids: [item2.id],
          limit: 7,
          type: 'see_also',
      )

      item1.update(shop_recommend: [item4.uniqid])
      item4.update(widgetable: true, is_available: true, ignored: false)
      expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item4.uniqid)
    end

    context 'industrial' do

      before {
        order = build(:order, shop: shop, user: other_user)
        [item1, item2, item3].each do |i|
          order.order_items.build(item: i, action_id: 123, shop_id: shop.id)
        end
        order.save!
      }

      let!(:params) { OpenStruct.new(shop: shop, user: user, item: item1, cart_item_ids: [item2.id], locations: [], limit: 7, type: 'see_also', skip_niche_algorithms: false, profile: profile) }

      context 'kids' do

        it 'includes male product for male kid' do
          item3.update is_child: true, child_gender: 'm'
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

        it 'excludes female product for male kid' do
          item3.update is_child: true, child_gender: 'f'
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to_not include(item3.uniqid)
        end

        it 'skip industrial filter for disabled' do
          params.skip_niche_algorithms = true
          item3.update is_child: true, child_gender: 'f'
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

        it 'skips industrial filter for 2 kids of different genders' do
          params.profile = People::Profile.new(children: [{'gender' => 'm'}, {'gender' => 'f'}])
          item3.update is_child: true, child_gender: 'f'
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

      end


      context 'jewelry' do

        before {
          item3.update is_jewelry: true, jewelry_gender: 'f', jewelry_color: 'yellow', jewelry_metal: 'gold', jewelry_gem: 'ruby', ring_sizes: ['16', '17', '18'], bracelet_sizes: ['16', '17', '18'], chain_sizes: ['16', '17', '18']
        }

        it 'skips jewelry filter if user has no jewelry' do
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

        it 'checks gender' do
          params.profile = People::Profile.new(jewelry: {'gender' => 'f'})
          expect( Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          params.profile = People::Profile.new(jewelry: {'gender' => 'm'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to_not include(item3.uniqid)
        end

        it 'checks materials' do
          params.profile = People::Profile.new(jewelry: {'color' => 'yellow', 'metal' => 'silver', 'gem' => 'diamond'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          params.profile = People::Profile.new(jewelry: {'color' => 'white', 'metal' => 'gold', 'gem' => 'diamond'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          params.profile = People::Profile.new(jewelry: {'color' => 'white', 'metal' => 'silver', 'gem' => 'ruby'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          params.profile = People::Profile.new(jewelry: {'color' => 'white', 'metal' => 'silver', 'gem' => 'diamond'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to_not include(item3.uniqid)
        end

        it 'checks sizes 1' do
          params.profile = People::Profile.new(jewelry: {'ring_size' => '16', 'bracelet_size' => '-', 'chain_size' => '-'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

        it 'checks sizes 2' do
          params.profile = People::Profile.new(jewelry: {'ring_size' => '-', 'bracelet_size' => '16', 'chain_size' => '-'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

        it 'checks sizes 3' do
          params.profile = People::Profile.new(jewelry: {'ring_size' => '-', 'bracelet_size' => '-', 'chain_size' => '16'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

        it 'checks sizes 4' do
          params.profile = People::Profile.new(jewelry: {'ring_size' => '16', 'bracelet_size' => '16', 'chain_size' => '16'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

        it 'checks sizes 5' do
          params.profile = People::Profile.new(jewelry: {'ring_size' => '15', 'bracelet_size' => '15', 'chain_size' => '15'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to_not include(item3.uniqid)
        end

        it 'checks full profile' do
          params.profile = People::Profile.new(jewelry: {'ring_size' => '16', 'bracelet_size' => '17', 'chain_size' => '18', 'color' => 'yellow', 'metal' => 'silver', 'gem' => 'diamond', 'gender' => 'f'})
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

      end

    end

  end
end
