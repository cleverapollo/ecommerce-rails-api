require 'rails_helper'

describe SubscriptionsController do
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }

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

    context 'if shop legislation it requires double opt-in' do
      let!(:mailings_settings) { create(:mailings_settings, shop: shop) }
      let!(:trigger_mailing) { create(:trigger_mailing, trigger_type: 'double_opt_in', shop: shop) }
      let(:email) { 'some@email.com' }
      before do
        shop.update(geo_law: Shop::GEO_LAWS[:canada])
      end

      context 'if trigger enabled' do
        before do
          trigger_mailing.update(enabled: true)
        end

        it 'send double opt-in trigger' do
          subject
          expect(response.code).to eq('200')
          expect(TriggerMail.count).to eq 1
        end
      end

      context 'if trigger disabled' do
        before do
          trigger_mailing.update(enabled: false)
        end

        it 'no send double opt-in trigger' do
          subject
          expect(response.code).to eq('200')
          expect(TriggerMail.count).to eq 0
        end
      end
    end

    context 'with bounced email (invalid)' do
      let(:email) { 'some@email.com' }
      let!(:invalid_email) { create(:invalid_email, email: email) }

      it 'skip exist' do
        subject
        expect(client.reload.email).to eq(nil)
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

  describe 'POST subscribe_for_product_price' do
    let!(:session) { create(:session_with_user) }
    let!(:client) { create(:client, user: session.user, shop: shop, email: nil, triggers_enabled: false) }
    let!(:item) { create(:item, shop: shop, uniqid: '123') }
    subject { post :subscribe_for_product_price, shop_id: shop.uniqid, ssid: session.code, email: email, item_id: item.uniqid }

    context 'all correct' do
      let!(:email) { 'some@email.com' }

      it 'saves email and subscribes to triggers' do
        subject
        expect(client.reload.email).to eq(email)
        expect(client.reload.triggers_enabled).to be_truthy
      end

      it 'saves subscription' do
        expect{subject}.to change(SubscribeForProductPrice, :count).by(1)
      end

    end

    context 'subscription already exists' do

      let!(:email) { 'some@email.com' }

      it 'does not duplicate subscription' do
        subject
        expect{subject}.to_not change(SubscribeForProductPrice, :count)
      end

    end

    context 'product does not exist' do

      let!(:email) { 'some@email.com' }

      it 'sends does not change anything' do
        item.destroy
        subject
        expect(response.code).to eq("200")
        expect{subject}.to_not change(SubscribeForProductPrice, :count)
      end

    end

    context 'incorrect email' do

      let!(:email) { 'potato' }

      it 'sends does not change anything' do
        item.destroy
        subject
        expect(response.code).to eq("200")
        expect{subject}.to_not change(SubscribeForProductAvailable, :count)
      end

    end

    context 'client with email' do

      let!(:email) { 'some@email.com' }

      it 'changes client`s email to new one' do
        client.update email: 'some2@email.com'
        subject
        expect(client.reload.email).to eq(email)
      end

    end

    context 'other client with this email' do

      let!(:email) { 'some@email.com' }
      let!(:session_2) { create(:session_with_user, code: '321321') }
      let!(:client_2) { create(:client, user: session_2.user, shop: shop, email: email, triggers_enabled: false) }

      it 'merges users' do
        subject
        expect{client.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect(client_2.reload.email).to eq(email)
        expect(session.reload.user_id).to eq(session_2.user_id)
      end

    end

  end

  describe 'POST subscribe_for_product_available' do
    let!(:session) { create(:session_with_user) }
    let!(:client) { create(:client, user: session.user, shop: shop, email: nil, triggers_enabled: false) }
    let!(:item) { create(:item, shop: shop, uniqid: '123', is_available: false) }
    subject { post :subscribe_for_product_available, shop_id: shop.uniqid, ssid: session.code, email: email, item_id: item.uniqid }

    context 'all correct' do

      let!(:email) { 'some@email.com' }

      it 'saves email and subscribes to triggers' do
        subject
        expect(client.reload.email).to eq(email)
        expect(client.reload.triggers_enabled).to be_truthy
      end

      it 'saves subscription' do
        expect{subject}.to change(SubscribeForProductAvailable, :count).by(1)
      end

    end

    context 'subscription already exists' do

      let!(:email) { 'some@email.com' }

      it 'does not duplicate subscription' do
        subject
        expect{subject}.to_not change(SubscribeForProductAvailable, :count)
      end

    end

    context 'product does not exist' do

      let!(:email) { 'some@email.com' }

      it 'sends does not change anything' do
        item.destroy
        subject
        expect(response.code).to eq("200")
        expect{subject}.to_not change(SubscribeForProductAvailable, :count)
      end

    end

    context 'incorrect email' do

      let!(:email) { 'potato' }

      it 'sends does not change anything' do
        item.destroy
        subject
        expect(response.code).to eq("200")
        expect{subject}.to_not change(SubscribeForProductAvailable, :count)
      end

    end

    context 'client with email' do

      let!(:email) { 'some@email.com' }

      it 'changes client`s email to new one' do
        client.update email: 'some2@email.com'
        subject
        expect(client.reload.email).to eq(email)
      end

    end

    context 'other client with this email' do

      let!(:email) { 'some@email.com' }
      let!(:session_2) { create(:session_with_user, code: '321321') }
      let!(:client_2) { create(:client, user: session_2.user, shop: shop, email: email, triggers_enabled: false) }

      it 'merges users' do
        subject
        expect{client.reload}.to raise_error(ActiveRecord::RecordNotFound)
        expect(client_2.reload.email).to eq(email)
        expect(session.reload.user_id).to eq(session_2.user_id)
      end

    end

    context 'product is available' do

      let!(:email) { 'some@email.com' }

      it 'sends does not change anything' do
        item.update is_available: true
        subject
        expect(response.code).to eq("200")
        expect{subject}.to_not change(SubscribeForProductAvailable, :count)
      end

    end

  end


end
