require 'rails_helper'

describe Recommender::Impl::AlsoBought do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:item1) { create(:item, shop: shop) }
  let!(:item2) { create(:item, shop: shop) }
  let!(:item3) { create(:item, shop: shop) }
  let!(:item4) { create(:item, shop: shop) }

  describe '#items_to_weight' do
    it 'returns ids of also bought items' do
      order = build(:order, shop: shop, user: other_user)

      [item1, item2, item3].each do |i|
        order.order_items.build(item: i, action_id: 123)
      end

      order.save!

      params = OpenStruct.new(
        shop: shop,
        user: user,
        item: item1,
        cart_item_ids: [item2.id],
        locations: []
      )

      recommender = Recommender::Impl::AlsoBought.new(params)

      result = recommender.items_to_weight

      expect(result).to match_array([item3.id])
    end
  end
end
