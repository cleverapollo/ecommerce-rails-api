require 'rails_helper'

describe RecommendationsController do
  let!(:shop) { create(:shop, uniqid: rand.to_s) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, code: rand.to_s, user: user) }
  # let!(:extracted_params) { {recommender_type: 'interesting' } }
  let!(:extracted_params) { Recommendations::Params.extract({ shop_id: shop.uniqid, ssid: session.code, recommender_type: 'interesting' }) }
  let!(:sample_recommendations) { [1, 2, 3] }
  before { allow(Recommendations::Params).to receive(:extract).and_return(extracted_params) }
  before { allow(Recommendations::Processor).to receive(:process).and_return(sample_recommendations) }
  let!(:params) { { shop_id: shop.uniqid } }

  it 'extracts parameters' do
    get :get, params

    expect(Recommendations::Params).to have_received(:extract)
  end

  context 'when all goes fine' do
    it 'passes parameters to recommendations handler' do
      get :get, params

      expect(Recommendations::Processor).to have_received(:process).with(extracted_params)
    end

    it 'responds with json array of recommendations' do
      get :get, params

      expect(response.body).to eq(sample_recommendations.to_json)
    end
  end

  context 'when error happens' do
    before { allow(Recommendations::Params).to receive(:extract).and_raise(Recommendations::IncorrectParams.new) }

    it 'responds with client error' do
      get :get, params

      expect(response.status).to eq(400)
    end
  end

  context 'when shop have outstanding plans' do

    let!(:subscription_plan) { create(:subscription_plan, shop: shop, active: true, paid_till: 2.days.ago, price: 100, product: 'rees46_recommendations') }

    it 'responds with client error' do
      get :get, params
      expect(response.status).to eq(400)
    end

    it 'response with success if plan is not about recommendations' do
      subscription_plan.update product: 'rees46_triggers'
      get :get, params
      expect(response.body).to eq(sample_recommendations.to_json)
    end

  end


  # @mk: выше тесты не позволяют выполнять эту проверку, т.к. перезаписывают поведение классов Recommendations::Params
  # context 'saves category subscription' do
  #
  #   let!(:item_category) { create(:item_category, shop: shop) }
  #   let!(:popular_params) { { shop_id: shop.uniqid, ssid: session.code, recommender_type: 'popular', categories: [item_category.external_id] } }
  #
  #   it 'increases amount of subscriptions' do
  #     get :get, popular_params
  #     expect(SubscribeForCategory.count).to eq(1)
  #   end
  #
  #   it 'does not increase amount of subscriptions' do
  #     popular_params.delete(:categories)
  #     get :get, popular_params
  #     expect(SubscribeForCategory.count).to eq(1)
  #   end
  #
  # end


end
