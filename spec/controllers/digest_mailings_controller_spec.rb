require 'rails_helper'

describe DigestMailingsController do
  describe 'GET launch' do
    let(:shop) { create(:shop) }
    before {
      allow(DigestMailingLaunchWorker).to receive(:perform_async)
    }

    context 'params validation' do
      it 'responds with 400 when shop not found' do
        post :launch, shop_id: 'potato', shop_secret: 'potato', email: 'test@example.com', id: 123
        expect(response.code).to eq('400')
      end
    end

    context 'with valid params' do
      let(:valid_params) { { shop_id: shop.uniqid, shop_secret: shop.secret, id: 123 } }

      it 'responds with 200' do
        post :launch, valid_params
        expect(response.code).to eq('200')
      end

      it 'starts DigestMailingLaunchWorker' do
        post :launch, valid_params
        expect(DigestMailingLaunchWorker).to have_received(:perform_async)
      end
    end
  end
end
