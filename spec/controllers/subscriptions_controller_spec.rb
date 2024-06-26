require 'rails_helper'

describe SubscriptionsController do
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }

  before do
    allow_any_instance_of(Elasticsearch::Persistence::Repository::Class).to receive(:delete)
  end

  describe 'GET unsubscribe' do
    let!(:client) { create(:client, :with_email, shop: shop).reload }
    let!(:shop_email) { create(:shop_email, shop: shop, email: client.email) }

    context 'for trigger mailings' do
      it 'sets client triggers_enabled to false' do
        expect(shop_email.triggers_enabled).to eq(true)
        get :unsubscribe, type: 'trigger', code: shop_email.code, shop_id: shop.uniqid
        expect(shop_email.reload.triggers_enabled).to eq(false)
      end
    end

    context 'for digest mailings' do
      it 'sets client digests_enabled to false' do
        expect(shop_email.digests_enabled).to eq(true)
        get :unsubscribe, type: 'digest', code: shop_email.code, shop_id: shop.uniqid
        expect(shop_email.reload.digests_enabled).to eq(false)
        expect(ShopEmail.find_by(email: client.email).digests_enabled).to be_falsey
      end
    end

    context 'for correct message' do
      let!(:mailings_settings) { create(:mailings_settings, shop: shop, unsubscribe_message: 'test') }
      subject { get :unsubscribe, type: 'trigger', code: shop_email.code, shop_id: shop.uniqid }
      it 'sets client triggers_enabled to false' do
        subject
        expect(response).to redirect_to("#{Rees46.site_url}/mailings/unsubscribed?code=#{shop_email.code}&type=trigger")
        expect(shop_email.reload.triggers_enabled).to eq(false)
      end
    end
  end

  describe 'GET track' do
    context 'for digest mailings' do
      let!(:mailing) { create(:digest_mailing, shop: shop) }
      let!(:batch) { create(:digest_mailing_batch, mailing: mailing, shop: shop) }
      let!(:client) { create(:client, :with_email, shop: shop).reload }
      let!(:shop_email) { create(:shop_email, shop: shop, email: client.email) }
      let!(:digest_mail) { create(:digest_mail, shop_email: shop_email, shop: shop, mailing: mailing, batch: batch).reload }

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

      context 'attach to segment' do
        let!(:segment) { create(:segment, shop: shop) }
        let!(:subscriptions_settings) { create(:subscriptions_settings, shop: shop, segment: segment) }

        it 'saves segment_id' do
          subject
          expect(client.reload.segment_ids).to eq([segment.id])
        end
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
          expect(ShopEmail.first.email_confirmed).to be_falsey
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
    let!(:client) { create(:client, user: session.user, shop: shop, email: nil) }
    let!(:item) { create(:item, shop: shop, uniqid: '123') }
    subject { post :subscribe_for_product_price, shop_id: shop.uniqid, ssid: session.code, email: email, item_id: item.uniqid }

    context 'all correct' do
      let!(:email) { 'some@email.com' }

      it 'saves email and subscribes to triggers' do
        subject
        expect(client.reload.email).to eq(email)
        expect(client.shop_email.triggers_enabled).to be_truthy
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

  end

  describe 'POST subscribe_for_product_available' do
    let!(:session) { create(:session_with_user) }
    let!(:client) { create(:client, user: session.user, shop: shop, email: nil) }
    let!(:item) { create(:item, shop: shop, uniqid: '123', is_available: false) }
    subject { post :subscribe_for_product_available, shop_id: shop.uniqid, ssid: session.code, email: email, item_id: item.uniqid }

    context 'all correct' do

      let!(:email) { 'some@email.com' }

      it 'saves email and subscribes to triggers' do
        subject
        expect(client.reload.email).to eq(email)
        expect(client.shop_email.triggers_enabled).to be_truthy
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
