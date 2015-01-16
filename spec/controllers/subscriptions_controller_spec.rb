require 'rails_helper'

describe SubscriptionsController do
  let!(:shop) { create(:shop) }

  describe 'GET unsubscribe' do
    pending "Broken"
  end

  describe 'GET track' do
    context 'for digest mailings' do
      let!(:mailing) { create(:digest_mailing, shop: shop) }
      let!(:batch) { create(:digest_mailing_batch, mailing: mailing) }
      let!(:audience) { create(:audience, shop: shop).reload }
      let!(:digest_mail) { create(:digest_mail, audience: audience, shop: shop, mailing: mailing, batch: batch).reload }

      pending "Broken"
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
