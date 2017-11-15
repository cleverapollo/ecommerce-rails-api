require 'rails_helper'

describe Recommender::Impl::RecentlyViewed do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:other_user) { create(:user) }
  let!(:item1) { create(:item, shop: shop, category_ids: '{3}', name:nil) }
  let!(:item2) { create(:item, shop: shop, category_ids: '{3,5}') }
  let!(:item3) { create(:item, shop: shop, category_ids: '{7}') }
  let!(:item4) { create(:item, shop: shop, category_ids: '{12}') }


  def create_action(user_data, item, is_buy = false)
    ActionCl.create!(shop: shop, session: user_data.sessions.first, current_session_code: 'test', event: is_buy ? 'purchase' : 'view', object_type: 'Item', object_id: item.uniqid, date: 1.day.ago.to_date, created_at: 1.day.ago, useragent: 'test')
  end


  describe '#recommendations' do

    before { create_action(user, item1) }
    before { create_action(user, item2) }
    before { create_action(user, item3) }
    before { create_action(user, item4) }

    it 'returns ids of recently viewed items' do

      params = OpenStruct.new(
          shop: shop,
          user: user,
          session: session,
          locations: [],
          limit:7,
          type: 'recently_viewed',
          #extended:true
      )

      recommender = Recommender::Impl::RecentlyViewed.new(params)

      result = recommender.recommendations

      #expect(result).to include({:id => item4.id.to_s, :name => "test", :url => "http://example.com/item/123", :image_url => "http://example.com/item/123.jpg", :price => "100.0"})
      #expect(result).not_to include(item1.uniqid)
      expect(result).to include(item1.uniqid)

    end
  end
end
