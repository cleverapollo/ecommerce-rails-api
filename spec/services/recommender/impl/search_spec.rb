require 'rails_helper'

describe Recommender::Impl::Search do

  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }

  let!(:item_1) { create(:item, shop: shop, is_available: true, sales_rate: 100, pets_periodic: true) }
  let!(:item_2) { create(:item, shop: shop, is_available: true, sales_rate: 100, pets_periodic: true) }
  let!(:item_3) { create(:item, shop: shop, is_available: true, sales_rate: nil, pets_periodic: true) }

  let!(:action) { create(:action, user: user, shop: shop, item: item_1) }

  let!(:order_1) { create(:order, shop: shop, user: user, uniqid: '123', date: Date.current) }
  let!(:order_item_1_1) { create(:order_item, shop: shop, order: order_1, item: item_1, action: action) }
  let!(:order_item_1_2) { create(:order_item, shop: shop, order: order_1, item: item_2, action: action) }
  let!(:order_2) { create(:order, shop: shop, user: user, uniqid: '456', date: Date.current) }
  let!(:order_item_2_1) { create(:order_item, shop: shop, order: order_2, item: item_2, action: action) }
  let!(:order_item_2_2) { create(:order_item, shop: shop, order: order_2, item: item_3, action: action) }

  let!(:search_query) { create(:search_query, shop: shop, date: Date.current, user: user) }




  describe '#recommendations' do

    it 'returns ids of searched and bought products' do

      params = OpenStruct.new(
          shop: shop,
          user: user,
          locations: [],
          limit: 5,
          type: 'search',
          search_query: search_query.query
      )

      recommender = Recommender::Impl::Search.new(params)
      result = recommender.recommendations

      expect(result.include?( item_1.uniqid )).to be_truthy
      expect(result.include?( item_2.uniqid )).to be_truthy
      expect(result.include?( item_3.uniqid )).to be_falsey

    end

  end





end
