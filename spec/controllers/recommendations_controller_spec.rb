require 'rails_helper'

describe RecommendationsController do
  before { @extracted_params = { recommender_type: 'interesting' } }
  before { allow(Recommendations::Params).to receive(:extract).and_return(@extracted_params) }
  before { @sample_recommendations = [1, 2, 3] }
  before { allow(Recommendations::Processor).to receive(:process).and_return(@sample_recommendations) }

  it 'extracts parameters' do
    get :get, @params

    expect(Recommendations::Params).to have_received(:extract)
  end

  context 'when all goes fine' do
    it 'passes parameters to recommendations handler' do
      get :get, @params

      expect(Recommendations::Processor).to have_received(:process).with(@extracted_params)
    end

    it 'responds with json array of recommendations' do
      get :get, @params

      expect(response.body).to eq(@sample_recommendations.to_json)
    end
  end

  context 'when error happens' do
    before { allow(Recommendations::Params).to receive(:extract).and_raise(Recommendations::IncorrectParams.new) }

    it 'responds with client error' do
      get :get, @params

      expect(response.status).to eq(400)
    end
  end
end
