require 'rails_helper'

describe Recommender::Impl::SeeAlso do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
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

      recommender = Recommender::Impl::AlsoBought.new(params)

      result = recommender.recommendations

      expect(result).to include(item3.uniqid)
    end

  end
end