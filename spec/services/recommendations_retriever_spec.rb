require 'spec_helper'

describe RecommendationsRetriever do
  let(:shop) { create(:shop) }
  let(:user) { create(:user) }
  let(:item1) { create(:item, shop: shop, category_uniqid: '1') }
  let(:item2) { create(:item, shop: shop, category_uniqid: '2') }
  let(:item3) { create(:item, shop: shop, category_uniqid: '1') }
  before {
    Action.create(shop: shop, user: user, item: item1, rating: 5, category_uniqid: '1', timestamp: 1.day.ago.to_i)
    Action.create(shop: shop, user: user, item: item2, rating: 3.2, category_uniqid: '2', timestamp: 1.day.ago.to_i)
    Action.create(shop: shop, user: user, item: item3, rating: 3.2, category_uniqid: '1', timestamp: 1.day.ago.to_i)
  }

  describe '#viewed_but_not_bought' do
    let!(:retriever) { RecommendationsRetriever.new(shop, 15) }
    before { retriever.user = user }

    it 'returns only viewed item_ids, but not bought' do
      expect(retriever.viewed_but_not_bought).to match_array([item2.id])
    end
  end
end
