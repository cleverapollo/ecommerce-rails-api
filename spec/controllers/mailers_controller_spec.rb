require 'spec_helper'

describe MailersController do
  describe "POST digest" do
    let!(:shop) { create(:shop) }
    context 'with correct shop credentials' do
      before { allow(DigestMailerWorker).to receive(:perform_async) }
      let!(:mailers_digest_params) { create(:mailers_digest_params, shop_id: shop.uniqid, shop_secret: shop.secret) }

      it 'responds with 200' do
        post :digest, mailers_digest_params

        expect(response.code).to eq('200')
      end

      it 'passes params to mailers_worker' do
        post :digest, mailers_digest_params

        expect(DigestMailerWorker).to have_received(:perform_async)
      end
    end

    context 'with incorrect shop credentials' do
      let!(:mailers_digest_params) { create(:mailers_digest_params, shop_id: shop.uniqid, shop_secret: 'wrong secret') }

      it 'responds with 400' do
        post :digest, mailers_digest_params

        expect(response.code).to eq('400')
      end
    end
  end
end
