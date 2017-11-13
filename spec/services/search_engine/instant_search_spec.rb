require 'rails_helper'

describe SearchEngine::InstantSearch do

  let!(:shop) { create(:shop, has_products_jewelry: true, has_products_kids: true, has_products_fashion: true, has_products_pets: true, has_products_cosmetic: true, has_products_fmcg: true, has_products_auto: true) }
  let!(:user) { create(:user, gender: 'm') }
  let!(:test_item) { create(:item, shop: shop, sales_rate: 10000, discount: true) }
  let!(:test_item_small_sr) { create(:item, shop: shop, sales_rate: 100) }

  let!(:params) { OpenStruct.new(shop: shop, user: user, limit: 12, type: 'instant_search', search_query: 'lua') }


  describe '#recommendations' do
    context 'default instant search' do
      it 'returns empty response' do
        recommender = SearchEngine::InstantSearch.new(params)
        expect(recommender.recommendations).to eq ({ products: [], categories: [], virtual_categories: [], keywords: [], queries: [], collections: [] })
      end
    end


    context 'when have search queries history' do
      # Важно - поисковые запросы, запрошенные один раз, игнорируются
      let!(:search_query_1) { create(:search_query, shop: shop, user: user, date: Date.current, query: 'popular') }
      let!(:search_query_2) { create(:search_query, shop: shop, user: user, date: Date.current, query: 'popular') }
      let!(:search_query_3) { create(:search_query, shop: shop, user: user, date: Date.current, query: 'popular') }
      let!(:search_query_4) { create(:search_query, shop: shop, user: user, date: Date.current, query: 'non popular') }
      let!(:search_query_5) { create(:search_query, shop: shop, user: user, date: Date.current, query: 'non popular') }

      it 'returns queries in specific order' do
        params[:search_query] = 'pop'
        recommender = SearchEngine::InstantSearch.new(params)
        expect(recommender.recommendations).to eq ({ products: [], categories: [], virtual_categories: [], keywords: [], queries: [], collections: [] })
      end
    end
  end
end
