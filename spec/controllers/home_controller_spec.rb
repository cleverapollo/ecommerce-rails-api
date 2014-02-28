require 'spec_helper'

describe HomeController do
  describe 'GET index' do
    it 'responds with 200' do
      get :index
      expect(response.status).to eq(200)
    end
  end
end
