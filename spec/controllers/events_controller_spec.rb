require 'rails_helper'

describe EventsController do

  describe 'POST push_attributes' do
    before { allow(UserProfile::AttributesProcessor).to receive(:process) }
    let(:shop) { create(:shop) }
    let(:user) { create(:user) }
    let(:session) { create(:session, user: user) }
    let!(:params) { { shop_id: shop.uniqid, session_id: session.code, attributes: { gender: 'f', size: 'e35', type: 'shoe' } } }
    subject { post :push_attributes, params }

    context 'params validation' do
      context 'when shop_id is invalid' do
        before { params[:shop_id] = 'potato' }

        it 'responds with 400' do
          subject
          expect(response.code).to eq('400')
        end
      end
      context 'when session_id is invalid' do
        before { params[:session_id] = 'potato' }

        it 'responds with 400' do
          subject
          expect(response.code).to eq('400')
        end
      end
    end
    context 'when params are valid' do
      it 'responds with ok message' do
        subject
        expect(response.body).to eq({ status: 'success' }.to_json)
      end

      it 'calls ProfileAttributesProcessor.process with shop and session' do
        subject
        expect(UserProfile::AttributesProcessor).to have_received(:process).with(shop, session.user, params[:attributes])
      end
    end
  end

  describe 'POST push' do
    before { allow(ActionPush::Params).to receive(:extract).and_return(OpenStruct.new(action: 'view')) }
    before { allow(ActionPush::Processor).to receive(:new).and_return(ActionPush::Processor.new(OpenStruct.new(action: 'view'))) }
    before { allow_any_instance_of(ActionPush::Processor).to receive(:process).and_return(true) }
    let!(:shop) { create(:shop) }
    let!(:session) { create(:session, user: create(:user)) }
    let(:params) { { shop_id: shop.uniqid, ssid: session.code }  }

    it 'extracts parameters' do
      post :push, params

      expect(ActionPush::Params).to have_received(:extract)
    end

    it 'passes extracted parameters to push service' do
      post :push, params

      expect(ActionPush::Processor).to have_received(:new)
    end

    context 'when all goes fine' do
      it 'responds with ok status' do
        post :push, params

        expect(response.status).to eq(200)
      end

      it 'responds with ok message' do
        post :push, params

        expect(response.body).to eq({ status: 'success' }.to_json)
      end
    end

    context 'when error happens' do
      before { allow(ActionPush::Params).to receive(:extract).and_raise(ActionPush::Error.new) }
      it 'responds with client error' do
        post :push, params

        expect(response.status).to eq(400)
      end
    end
  end

  describe 'POST push purchase' do
    let!(:shop) { create(:shop) }
    let!(:session) { create(:session, user: create(:user)) }
    let!(:client) { create(:client, user: create(:user), shop: shop) }
    let(:params) { { shop_id: shop.uniqid, ssid: session.code, event: 'purchase', order_id: '1', order_price: '1000', item_id: ['20'], amount: ['1'], price: ['1000'] } }

    it 'default' do
      post :push, params

      expect(Order.count).to eq 1
    end

    context 'purchase with source type' do
      let!(:digest_mailing) { create(:digest_mailing, shop: shop) }
      let!(:batch) { create(:digest_mailing_batch, shop: shop, mailing: digest_mailing) }
      let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'abandoned_cart', liquid_template: '123') }

      let!(:digest_mail) { create(:digest_mail, shop_id: shop.id, mailing: digest_mailing, batch: batch, client: client) }
      let!(:trigger_mail) { create(:trigger_mail, shop_id: shop.id, mailing: trigger_mailing, trigger_data: {a: 1}, client: client) }
      let!(:rtb_impression) { create(:rtb_impression, shop: shop) }

      let!(:web_push_digest_message) { create(:web_push_digest_message, shop: shop, client: client) }
      let!(:web_push_trigger_message) { create(:web_push_trigger_message, shop: shop, client: client, trigger_data: {a: 1}, web_push_trigger_id: 1) }

      it 'digest_mail' do
        post :push, params.merge({source: "{\"from\":\"digest_mail\",\"code\":\"#{digest_mail.code}\"}"})

        expect(Order.where(source_type: 'DigestMail').count).to eq 1
      end

      it 'trigger_mail' do
        post :push, params.merge({source: "{\"from\":\"trigger_mail\",\"code\":\"#{trigger_mail.code}\"}"})

        expect(Order.where(source_type: 'TriggerMail').count).to eq 1
      end

      it 'r46_returner' do
        post :push, params.merge({source: "{\"from\":\"r46_returner\",\"code\":\"#{rtb_impression.code}\"}"})

        expect(Order.where(source_type: 'RtbImpression').count).to eq 1
      end

      it 'web_push_digest' do
        post :push, params.merge({source: "{\"from\":\"web_push_digest\",\"code\":\"#{web_push_digest_message.code}\"}"})

        expect(Order.where(source_type: 'WebPushDigestMessage').count).to eq 1
      end

      it 'web_push_trigger' do
        post :push, params.merge({source: "{\"from\":\"web_push_trigger\",\"code\":\"#{web_push_trigger_message.code}\"}"})

        expect(Order.where(source_type: 'WebPushTriggerMessage').count).to eq 1
      end
    end
  end
end
