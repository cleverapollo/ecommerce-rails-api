require 'rails_helper'

describe SubscriptionsController do
  let!(:shop) { create(:shop) }

  describe 'GET bounce' do
    let!(:shops_user) { create(:shops_user, shop: shop, email: 'test@example.com') }

    context 'for digest mailings' do
      let!(:digest_mailing) { create(:digest_mailing, shop: shop) }
      let!(:digest_mailing_batch) { create(:digest_mailing_batch, mailing: digest_mailing)  }
      let!(:digest_mail) { create(:digest_mail, shop: shop, shops_user: shops_user, batch: digest_mailing_batch, mailing: digest_mailing).reload }

      it 'marks digest_mail as bounced' do
        expect(digest_mail.bounced).to eq(false)
        get :bounce, type: 'digest', code: digest_mail.code
        expect(digest_mail.reload.bounced).to eq(true)
      end

      it 'cleans shops_user email' do
        expect(shops_user.email).to be_present
        get :bounce, type: 'digest', code: digest_mail.code
        expect(shops_user.reload.email).to be_blank
      end
    end

    context 'for trigger mailings' do
      pending 'Not implemented'
    end
  end

  describe 'GET unsubscribe' do
    let!(:shops_user) { create(:shops_user, shop: shop).reload }

    context 'for trigger mailings' do
      it 'sets shops_user triggers_enabled to false' do
        expect(shops_user.triggers_enabled).to eq(true)
        get :unsubscribe, type: 'trigger', code: shops_user.code
        expect(shops_user.reload.triggers_enabled).to eq(false)
      end
    end

    context 'for digest mailings' do
      it 'sets shops_user digests_enabled to false' do
        expect(shops_user.digests_enabled).to eq(true)
        get :unsubscribe, type: 'digest', code: shops_user.code
        expect(shops_user.reload.digests_enabled).to eq(false)
      end
    end
  end

  describe 'GET track' do
    context 'for digest mailings' do
      let!(:mailing) { create(:digest_mailing, shop: shop) }
      let!(:batch) { create(:digest_mailing_batch, mailing: mailing) }
      let!(:shops_user) { create(:shops_user, shop: shop).reload }
      let!(:digest_mail) { create(:digest_mail, shops_user: shops_user, shop: shop, mailing: mailing, batch: batch).reload }

      it 'sets digest_mail opened to true' do
        expect(digest_mail.opened).to eq(false)
        get :track, type: 'digest', code: digest_mail.reload.code
        expect(digest_mail.reload.opened).to eq(true)
      end
    end

    context 'for trigger mailings' do
      let!(:subscription) { create(:subscription, shop: shop).reload }
      let!(:trigger_mail) { create(:trigger_mail, shop: shop, subscription: subscription).reload }

      pending "Broken"
    end

    it 'responds with pixel' do
      get :track, type: 'test', code: 'test'
      expect(response.content_type).to eq('image/png')
    end
  end

  describe 'POST create' do
    let(:session) { create(:session_with_user) }
    let!(:shops_user) { create(:shops_user, user: session.user, shop: shop, email: nil) }
    let(:declined) { false }
    subject { post :create, shop_id: shop.uniqid, ssid: session.code, email: email, declined: declined }

    context 'with valid email' do
      let(:email) { 'some@email.com' }

      it 'saves email' do
        subject
        expect(shops_user.reload.email).to eq(email)
      end

      it 'marks shops_user subscription_popup_showed as true' do
        subject
        expect(shops_user.reload.subscription_popup_showed).to eq(true)
      end

      it 'marks shops_user accepted_subscription as true' do
        subject
        expect(shops_user.reload.accepted_subscription).to eq(true)
      end
    end

    context 'declining' do
      let(:email) { nil }
      let(:declined) { true }

      it 'marks shops_user subscription_popup_showed as true' do
        subject
        expect(shops_user.reload.subscription_popup_showed).to eq(true)
      end

      it 'marks shops_user accepted_subscription as false' do
        subject
        expect(shops_user.reload.accepted_subscription).to eq(false)
      end
    end

    context 'with invalid email' do
      let(:email) { 'potato' }

      it 'doesnt saves email' do
        subject
        expect(shops_user.reload.email).to eq(nil)
      end
    end
  end
end
