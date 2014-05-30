require 'spec_helper'

describe MailingsController do
  let!(:shop) { create(:shop) }

  describe 'POST create' do
    context 'with valid show credentials' do
      let!(:params) do
        {
          shop_id: shop.uniqid,
          shop_secret: shop.secret,
          send_from: 'TesterBot <tester@bot.com>',
          subject: 'TestMail',
          template: '<h1>TestMail</h1>',
          items: [ { id: 1 } ],
          recommendations_limit: 5
        }
      end

      it 'responds with 200' do
        post :create, params

        expect(response.code).to eq('200')
      end

      it 'creates mailing' do
        expect {
          post :create, params
        }.to change(Mailing, :count).from(0).to(1)
      end

      it 'returns token' do
        post :create, params

        expect(response.body).to eq(Mailing.first.token)
      end
    end

    context 'with invalid shop credentials' do
      it 'responds with 400' do
        post :create, { shop_id: shop.uniqid, shop_secret: 'qwe123' }
        expect(response.code).to eq('400')
      end
    end
  end

  describe 'POST perform' do
    let!(:mailing) { create(:mailing, shop: shop) }

    context 'with valid mailing token' do
      let(:params) do
        {
          shop_id: shop.uniqid,
          shop_secret: shop.secret,
          id: mailing.token,
          users: [ { id: 1 } ]
        }
      end

      it 'fetches mailing' do
        post :perform, params
        expect(assigns(:mailing)).to eq(mailing)
      end

      it 'responds with 200' do
        post :perform, params
        expect(response.code).to eq('200')
      end

      it 'responds with empty body' do
        post :perform, params
        expect(response.body.blank?).to be_true
      end

      it 'creates mailing batch' do
        expect{
          post :perform, params
        }.to change(MailingBatch, :count).from(0).to(1)
      end

      it 'calls the worker' do
        allow(MailingBatchWorker).to receive(:perform_async)
        allow_any_instance_of(MailingBatchWorker).to receive(:perform)

        post :perform, params

        expect(MailingBatchWorker).to have_received(:perform_async).with(MailingBatch.first!.id)
      end
    end

    context 'with invalid mailing token' do
      let(:params) do
        {
          shop_id: shop.uniqid,
          shop_secret: shop.secret,
          id: '12345',
          users: [ { id: 1 } ]
        }
      end

      it 'responds with 400' do
        post :perform, params

        expect(response.code).to eq('400')
      end
    end
  end
end
