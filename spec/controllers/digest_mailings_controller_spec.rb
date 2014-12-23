require 'rails_helper'

describe DigestMailingsController do
  describe 'GET recommendations' do
    let(:shop) { create(:shop) }
    before {
      allow(DigestMailingRecommendationsCalculatorWorker).to receive(:perform_async)
    }

    context 'params validation' do
      it 'responds with 400 when shop not found' do
        get :recommendations, shop_id: 'potato', shop_secret: 'potato', email: 'test@example.com'
        expect(response.code).to eq('400')
      end

      it 'responds with 400 if email is undefined' do
        get :recommendations, shop_id: shop.uniqid, shop_secret: shop.secret, email: ''
        expect(response.code).to eq('400')
      end
    end

    context 'with valid params' do
      let(:valid_params) { { shop_id: shop.uniqid, shop_secret: shop.secret, email: 'test@example.com' } }

      it 'responds with 200' do
        get :recommendations, valid_params
        expect(response.code).to eq('200')
      end

      it 'responds with OK' do
        get :recommendations, valid_params
        expect(response.body).to eq('OK')
      end

      it 'starts DigestMailingRecommendationsCalculatorWorker' do
        get :recommendations, valid_params
        expect(DigestMailingRecommendationsCalculatorWorker).to have_received(:perform_async)
      end
    end
  end
end
