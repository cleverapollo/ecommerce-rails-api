require 'rails_helper'

describe Recommender::Impl::RecentlyViewed do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }
  let!(:item1) { create(:item, shop: shop, categories: '{3}', name:nil) }
  let!(:item2) { create(:item, shop: shop, categories: '{3,5}') }
  let!(:item3) { create(:item, shop: shop, categories: '{7}') }
  let!(:item4) { create(:item, shop: shop, categories: '{12}') }


  def create_action(user_data, item, is_buy = false)
    a = item.actions.new(user: user_data,
                         shop: shop,
                         timestamp: 1.day.ago.to_i,
                         rating: Actions::View::RATING,
                        view_count: 1)

    if is_buy
      a.purchase_count = 1
      a.rating = Actions::Purchase::RATING
    end
    a.save
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
