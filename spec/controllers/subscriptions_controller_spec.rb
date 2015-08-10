require 'rails_helper'

describe SubscriptionsController do
  let!(:shop) { create(:shop) }

  describe 'GET unsubscribe' do
    let!(:client) { create(:client, shop: shop).reload }

    context 'for trigger mailings' do
      it 'sets client triggers_enabled to false' do
        expect(client.triggers_enabled).to eq(true)
        get :unsubscribe, type: 'trigger', code: client.code
        expect(client.reload.triggers_enabled).to eq(false)
      end
    end

    context 'for digest mailings' do
      it 'sets client digests_enabled to false' do
        expect(client.digests_enabled).to eq(true)
        get :unsubscribe, type: 'digest', code: client.code
        expect(client.reload.digests_enabled).to eq(false)
      end
    end
  end

  describe 'GET track' do
    context 'for digest mailings' do
      let!(:mailing) { create(:digest_mailing, shop: shop) }
      let!(:batch) { create(:digest_mailing_batch, mailing: mailing, shop: shop) }
      let!(:client) { create(:client, shop: shop).reload }
      let!(:digest_mail) { create(:digest_mail, client: client, shop: shop, mailing: mailing, batch: batch).reload }

      it 'sets digest_mail opened to true' do
        expect(digest_mail.opened).to eq(false)
        get :track, type: 'digest', code: digest_mail.reload.code
        expect(digest_mail.reload.opened).to eq(true)
      end
    end

    context 'for trigger mailings' do
      let!(:client) { create(:client, shop: shop).reload }
      let!(:trigger_mailing) { create(:trigger_mailing, shop: shop) }
      let!(:trigger_mail) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing).reload }

      it 'sets trigger_mail opened to true' do
        expect(trigger_mail.opened).to eq(false)
        get :track, type: 'trigger', code: trigger_mail.reload.code
        expect(trigger_mail.reload.opened).to eq(true)
      end
    end

    it 'responds with pixel' do
      get :track, type: 'test', code: 'test'
      expect(response.content_type).to eq('image/png')
    end
  end

  describe 'POST create' do
    let(:session) { create(:session_with_user) }
    let!(:client) { create(:client, user: session.user, shop: shop, email: nil) }
    let(:declined) { false }
    subject { post :create, shop_id: shop.uniqid, ssid: session.code, email: email, declined: declined }

    context 'with valid email' do
      let(:email) { 'some@email.com' }

      it 'saves email' do
        subject
        expect(client.reload.email).to eq(email)
      end

      it 'marks client subscription_popup_showed as true' do
        subject
        expect(client.reload.subscription_popup_showed).to eq(true)
      end

      it 'marks client accepted_subscription as true' do
        subject
        expect(client.reload.accepted_subscription).to eq(true)
      end
    end

    context 'declining' do
      let(:email) { nil }
      let(:declined) { true }

      it 'marks client subscription_popup_showed as true' do
        subject
        expect(client.reload.subscription_popup_showed).to eq(true)
      end

      it 'marks client accepted_subscription as false' do
        subject
        expect(client.reload.accepted_subscription).to eq(false)
      end
    end

    context 'with invalid email' do
      let(:email) { 'potato' }

      it 'doesnt saves email' do
        subject
        expect(client.reload.email).to eq(nil)
      end
    end
  end
end
