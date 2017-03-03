require 'rails_helper'

describe Recommender::Impl::SeeAlso do
  let!(:shop) { create(:shop, has_products_jewelry: true, has_products_kids: true, has_products_fashion: true, has_products_pets: true, has_products_cosmetic: true, has_products_fmcg: true, has_products_auto: true) }
  let!(:user) { create(:user, children: [{'gender' => 'm'}]) }
  let!(:other_user) { create(:user) }
  let!(:item1) { create(:item, shop: shop, category_ids: '{3}') }
  let!(:item2) { create(:item, shop: shop, category_ids: '{3,5}') }
  let!(:item3) { create(:item, shop: shop, category_ids: '{7}') }
  let!(:item4) { create(:item, shop: shop, category_ids: '{12}') }

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
          type: 'also_bought'
      )

      recommender = Recommender::Impl::SeeAlso.new(params)

      result = recommender.recommendations

      expect(result).to include(item3.uniqid)
    end


    context 'industrial' do

      before {
        order = build(:order, shop: shop, user: other_user)
        [item1, item2, item3].each do |i|
          order.order_items.build(item: i, action_id: 123, shop_id: shop.id)
        end
        order.save!
      }

      let!(:params) { OpenStruct.new(shop: shop, user: user, item: item1, cart_item_ids: [item2.id], locations: [], limit: 7, type: 'see_also') }

      context 'kids' do

        it 'includes male product for male kid' do
          item3.update is_child: true, child_gender: 'm'
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

        it 'excludes female product for male kid' do
          item3.update is_child: true, child_gender: 'f'
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to_not include(item3.uniqid)
        end

        it 'skips industrial filter for 2 kids of different genders' do
          user.update children: [{'gender' => 'm'}, {'gender' => 'f'}]
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
          user.update jewelry: {'gender' => 'f'}
          params.user = user
          expect( Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          user.update jewelry: {'gender' => 'm'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to_not include(item3.uniqid)
        end

        it 'checks materials' do
          user.update jewelry: {'color' => 'yellow', 'metal' => 'silver', 'gem' => 'diamond'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          user.update jewelry: {'color' => 'white', 'metal' => 'gold', 'gem' => 'diamond'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          user.update jewelry: {'color' => 'white', 'metal' => 'silver', 'gem' => 'ruby'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          user.update jewelry: {'color' => 'white', 'metal' => 'silver', 'gem' => 'diamond'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to_not include(item3.uniqid)
        end

        it 'checks sizes' do
          user.update jewelry: {'ring_size' => '16', 'bracelet_size' => '-', 'chain_size' => '-'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          user.update jewelry: {'ring_size' => '-', 'bracelet_size' => '16', 'chain_size' => '-'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          user.update jewelry: {'ring_size' => '-', 'bracelet_size' => '-', 'chain_size' => '16'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          user.update jewelry: {'ring_size' => '16', 'bracelet_size' => '16', 'chain_size' => '16'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
          user.update jewelry: {'ring_size' => '15', 'bracelet_size' => '15', 'chain_size' => '15'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to_not include(item3.uniqid)
        end

        it 'checks full profile' do
          user.update jewelry: {'ring_size' => '16', 'bracelet_size' => '17', 'chain_size' => '18', 'color' => 'yellow', 'metal' => 'silver', 'gem' => 'diamond', 'gender' => 'f'}
          params.user = user
          expect(Recommender::Impl::SeeAlso.new(params).recommendations).to include(item3.uniqid)
        end

      end

    end

  end
end
