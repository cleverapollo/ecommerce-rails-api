require 'rails_helper'

describe RecommendationsController do
  let!(:shop) { create(:shop, uniqid: rand.to_s) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, code: rand.to_s, user: user) }
  let!(:subscription_plan) { create(:subscription_plan, shop: shop, paid_till: 1.month.from_now, product: 'product.recommendations', price: 100) }
  # let!(:extracted_params) { {recommender_type: 'interesting' } }
  let!(:extracted_params) { Recommendations::Params.extract({ shop_id: shop.uniqid, ssid: session.code, recommender_type: 'interesting' }) }
  let!(:sample_recommendations) { [1, 2, 3] }
  before { allow(Recommendations::Params).to receive(:extract).and_return(extracted_params) }
  before { allow(Recommendations::Processor).to receive(:process).and_return(sample_recommendations) }
  let!(:params) { { shop_id: shop.uniqid } }

  context 'when all goes fine' do
    let!(:params) { { shop_id: shop.uniqid, ssid: session.code, recommender_type: 'interesting' } }
    it 'passes parameters to recommendations handler' do
      get :get, params

      expect(Recommendations::Processor).to have_received(:process)
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

    it 'responds with client error' do
      subscription_plan.update paid_till: 2.days.ago
      get :get, params
      expect(response.status).to eq(402)
    end

    it 'response with success if plan is not about recommendations' do
      subscription_plan.update product: 'trigger.emails', paid_till: 2.days.from_now
      get :get, params
      expect(response.status).to eq(402)

    end

  end

  context 'when also_bought empty' do
    before { allow(Recommendations::Processor).to receive(:process).and_return([]) }
    let!(:params) { { shop_id: shop.uniqid, ssid: session.code, recommender_type: 'also_bought', item_id: 1 } }

    it 'process exactly 1 times' do
      get :get, params

      expect(Recommendations::Processor).to have_received(:process).exactly(1).times
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
