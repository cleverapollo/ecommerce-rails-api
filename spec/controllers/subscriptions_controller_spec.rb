require 'spec_helper'

describe SubscriptionsController do
  let!(:shop) { create(:shop) }

  describe 'GET unsubscribe' do
    context 'for digest mailings' do
      let!(:audience) { create(:audience, shop: shop).reload }

      it 'disables audience by code' do
        get :unsubscribe, type: 'digest', code: audience.code
        expect(audience.reload.active).to be_false
      end
    end

    context 'for trigger mailings' do
      let!(:subscription) { create(:subscription, shop: shop).reload }

      it 'disables subscription by code' do
        get :unsubscribe, type: 'trigger', code: subscription.code

        expect(subscription.reload.active).to be_false
      end
    end
  end

  describe 'GET track' do
    context 'for digest mailings' do
      let!(:mailing) { create(:digest_mailing, shop: shop) }
      let!(:batch) { create(:digest_mailing_batch, mailing: mailing) }
      let!(:audience) { create(:audience, shop: shop).reload }
      let!(:digest_mail) { create(:digest_mail, audience: audience, shop: shop, mailing: mailing, batch: batch).reload }

      it 'marks digest mail as opened' do
        get :track, type: 'digest', code: digest_mail.code

        expect(digest_mail.reload.opened).to be_true
      end
    end

    context 'for trigger mailings' do
      let!(:subscription) { create(:subscription, shop: shop).reload }
      let!(:trigger_mail) { create(:trigger_mail, shop: shop, subscription: subscription).reload }

      it 'marks trigger mail as opened' do
        get :track, type: 'trigger', code: trigger_mail.code

        expect(trigger_mail.reload.opened).to be_true
      end
    end

    it 'responds with pixel' do
      get :track, type: 'test', code: 'test'
      expect(response.content_type).to eq('image/png')
    end
  end
end
