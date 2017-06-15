require 'rails_helper'

describe EventsController do
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:user) { create(:user) }

  describe 'POST push_attributes' do
    before { allow(UserProfile::AttributesProcessor).to receive(:process) }
    let(:session) { create(:session, user: user, code: SecureRandom.uuid) }
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

  describe 'POST push_attributes and client update' do
    let!(:shop_location) { create(:shop_location, shop: shop) }
    let!(:client) { create(:client, shop: shop, user: user) }
    let!(:session) { create(:session, user: user, code: SecureRandom.uuid) }
    let!(:params) { { shop_id: shop.uniqid, session_id: session.code, attributes: { gender: 'f', size: 'e35', type: 'shoe', location: shop_location.external_id } } }
    subject { post :push_attributes, params }

    it 'client location saved' do
      subject
      expect(Client.first.location).to eq(shop_location.external_id)
    end
  end

  describe 'POST push_attributes create ProfileEvent for user' do
    let!(:shop_location) { create(:shop_location, shop: shop) }
    let!(:client) { create(:client, shop: shop, user: user) }
    let!(:session) { create(:session, user: user, code: SecureRandom.uuid) }
    let!(:params) { { shop_id: shop.uniqid, session_id: session.code, attributes: { gender: 'f', kids: [{ gender: 'm', birthday: '2014-02-10' }, { gender: 'f', birthday: '2010-02-10' }] } } }
    subject { post :push_attributes, params }

    it 'client location saved' do
      subject
      expect(ProfileEvent.where(property: 'push_attributes_children').count).to eq 2
      expect(ProfileEvent.where(property: 'push_attributes_children').first.user).to eq Client.first.user
    end
  end

  describe 'POST push' do
    # before { allow(ActionPush::Params).to receive(:extract).and_return(OpenStruct.new(action: 'view')) }
    before { allow(ActionPush::Processor).to receive(:new).and_return(ActionPush::Processor.new(OpenStruct.new(action: 'view'))) }
    before { allow_any_instance_of(ActionPush::Processor).to receive(:process).and_return(true) }
    let!(:session) { create(:session, user: user, code: SecureRandom.uuid) }
    let(:params) { { shop_id: shop.uniqid, ssid: session.code }  }

    it 'extracts parameters when error' do
      post :push, params

      expect(response.status).to eq(400)
      expect(response.body).to eq({ status: 'error', message: 'Action not provided' }.to_json)
    end

    context 'when all goes fine' do
      let(:params) { { shop_id: shop.uniqid, ssid: session.code, event: 'view', item_id: {'0': '1'} }  }

      it 'passes extracted parameters to push service' do
        post :push, params

        expect(response.status).to eq(200)
      end

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
    let!(:session) { create(:session, user: user, code: SecureRandom.uuid) }
    let!(:client) { create(:client, user: user, shop: shop) }
    let(:params) { { shop_id: shop.uniqid, ssid: session.code, event: 'purchase', order_id: '1', order_price: '1000', item_id: ['20'], amount: ['1'], price: ['1000'] } }

    it 'default' do
      post :push, params

      expect(Order.count).to eq 1
    end

    it 'removes client carts after purchase' do
      ClientCart.all.destroy_all
      create(:client_cart, user_id: client.user_id, shop_id: shop.id, items: [1])
      expect(client.user.reload.client_carts.count).to eq 1
      post :push, params
      expect(client.user.reload.client_carts.count).to eq 0
    end

    context 'when existing old order' do
      let!(:order) { create(:order, shop: shop, uniqid: params[:order_id], date: 1.day.ago.to_date, user: create(:user), value: 100) }
      let!(:item) { create(:item, shop: shop, uniqid: 10) }
      let!(:action) { create(:action, user: order.user, item: item, shop: shop) }
      let!(:order_item) { create(:order_item, order: order, shop: shop, item: item, action: action) }

      it 'default' do
        post :push, params

        expect(Order.count).to eq 1
        expect(Order.first.id).to eq order.id
        expect(Order.first.user_id).to eq order.user_id
        expect(Order.first.value).to eq order.value
        expect(Order.first.date).to eq 1.day.ago.to_date
      end
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
        expect(OrderItem.where(recommended_by: 'digest_mail').count).to eq 1
      end

      it 'trigger_mail' do
        post :push, params.merge({source: "{\"from\":\"trigger_mail\",\"code\":\"#{trigger_mail.code}\"}"})

        expect(Order.where(source_type: 'TriggerMail').count).to eq 1
        expect(OrderItem.where(recommended_by: 'trigger_mail').count).to eq 1
      end

      it 'r46_returner' do
        post :push, params.merge({source: "{\"from\":\"r46_returner\",\"code\":\"#{rtb_impression.code}\"}"})

        expect(Order.where(source_type: 'RtbImpression').count).to eq 1
        expect(OrderItem.where(recommended_by: 'rtb_impression').count).to eq 1
      end

      it 'web_push_digest' do
        post :push, params.merge({source: "{\"from\":\"web_push_digest\",\"code\":\"#{web_push_digest_message.code}\"}"})

        expect(Order.where(source_type: 'WebPushDigestMessage').count).to eq 1
        expect(OrderItem.where(recommended_by: 'web_push_digest_message').count).to eq 1
      end

      it 'web_push_trigger' do
        post :push, params.merge({source: "{\"from\":\"web_push_trigger\",\"code\":\"#{web_push_trigger_message.code}\"}"})
        expect(Order.where(source_type: 'WebPushTriggerMessage').count).to eq 1
        expect(OrderItem.where(recommended_by: 'web_push_trigger_message').count).to eq 1
      end
    end
  end
end
