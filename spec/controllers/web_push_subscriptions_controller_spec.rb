require 'rails_helper'

describe WebPushSubscriptionsController do

  describe 'PATCH unsubscribe' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user, code: rand(111111111).to_s) }
    let!(:client) { create(:client, user: user, shop: shop, web_push_token: '123', web_push_browser: 'firefox', web_push_enabled: true, last_web_push_sent_at: 1.days.ago).reload }

    it 'sets client digests_enabled to false' do
      expect(client.web_push_enabled).to eq(true)
      patch :unsubscribe, shop_id: shop.uniqid, ssid: session.code
      expect(client.reload.web_push_token).to be_nil
      expect(client.reload.web_push_browser).to be_nil
      expect(client.reload.last_web_push_sent_at).to be_nil
      expect(client.reload.web_push_enabled).to be_nil
    end

  end

  describe 'POST create' do
    let!(:shop) { create(:shop) }
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user, code: rand(111111111).to_s) }
    let!(:client) { create(:client, user: session.user, shop: shop, email: nil) }

    subject { post :create, shop_id: shop.uniqid, ssid: session.code, token: '123', browser: 'safari' }

    context 'with valid data' do
      it 'saves subscription' do
        subject
        expect(client.reload.web_push_token).to eq('123')
        expect(client.reload.web_push_browser).to eq('safari')
        expect(client.reload.web_push_enabled).to be_truthy
      end
    end

    context 'with invalid data' do

      it 'doesnt have token' do
        post :create, shop_id: shop.uniqid, ssid: session.code, browser: 'safari'
        expect(client.reload.web_push_enabled).to eq(nil)
      end

      it 'doesnt have browser' do
        post :create, shop_id: shop.uniqid, ssid: session.code, token: '123'
        expect(client.reload.web_push_enabled).to eq(nil)
      end
    end

  end

end
