require 'rails_helper'

describe SearchController do
  let!(:shop) { create(:shop, uniqid: rand.to_s) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, code: rand.to_s, user: user) }
  let!(:subscription_plan) { create(:subscription_plan, shop: shop, paid_till: 1.month.from_now, product: 'product.search', price: 100) }
  let!(:extracted_params) { SearchEngine::Params.extract({ shop_id: shop.uniqid, ssid: session.code, type: 'instant_search', search_query: 'coat' }) }
  let!(:item) { create(:item, shop: shop) }
  let!(:sample_recommendations) { { products: [], categories: [], virtual_categories: [], keywords: [], } }
  before { allow(SearchEngine::Params).to receive(:extract).and_return(extracted_params) }
  before { allow(SearchEngine::Processor).to receive(:process).and_return(sample_recommendations) }
  let!(:params) { { shop_id: shop.uniqid } }

  context 'when all goes fine' do
    let!(:params) { { shop_id: shop.uniqid, ssid: session.code, type: 'instant_search', search_query: 'coat' } }
    it 'passes parameters to search handler' do
      get :get, params
      expect(SearchEngine::Processor).to have_received(:process)
    end

    it 'responds with json array of results' do
      get :get, params
      expect(response.body).to eq ({ products: [], categories: [], virtual_categories: [], keywords: [], queries: [], collections: []}).to_json
    end
  end

  context 'when error happens' do
    before { allow(SearchEngine::Params).to receive(:extract).and_raise(SearchEngine::IncorrectParams.new) }

    it 'responds with client error' do
      get :get, params

      expect(response.status).to eq(400)
    end
  end

  context 'when shop have outstanding plans' do

    it 'responds with client error' do
      subscription_plan.update paid_till: 2.days.ago
      get :get, params
      expect(response.status).to eq(402)
    end

    it 'response with success if plan is not about search' do
      subscription_plan.update product: 'trigger.emails', paid_till: 2.days.from_now
      get :get, params
      expect(response.status).to eq(402)

    end

  end



  context 'full search' do

    context 'search query store' do

      let!(:params) { { shop_id: shop.uniqid, ssid: session.code, type: 'full_search', search_query: 'coat' } }

      it 'saves search query' do
        get :get, params
        expect(SearchQuery.count).to eq 1
      end

      it 'does not save invalid search query' do
        params[:search_query] = '    '
        get :get, params
        expect(SearchQuery.count).to eq 0
      end

    end

  end


  context 'instant search' do

    let!(:params) { { shop_id: shop.uniqid, ssid: session.code, type: 'instant_search', search_query: 'coat' } }

    it 'does not save search query for instant search' do
      get :get, params
      expect(SearchQuery.count).to eq 0
    end

  end

  context 'saves no result query' do

    let!(:params) { { shop_id: shop.uniqid, ssid: session.code, type: 'full_search', search_query: 'topcoa' } }

    it 'save no result query for full search' do
      expect(NoResultQuery.count).to eq 0

      get :get, params
      expect(NoResultQuery.count).to eq 1
    end

  end

end
