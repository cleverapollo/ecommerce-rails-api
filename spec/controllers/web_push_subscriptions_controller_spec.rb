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

    subject { post :create, shop_id: shop.uniqid, ssid: session.code, token: "{\"endpoint\":\"https://updates.push.services.mozilla.com/wpush/v1/gAAAAABXl1UulZVga2J9KycmWioH5HbQrmD3f8yIxfE79GW5bh80G5Ndjm-XfJbSL9ekJ8QJ1fskCylQCfSLPvf7PlXb-W_OjC1dXqPMqK40VUFHsF8jADELInKVyifIORunYGtUBzvh\",\"keys\":{\"auth\":\"vJd60OQAvKNjDOFCQidYIA\",\"p256dh\":\"BKkAQRS74AUsuX3YfY60D7LSm1xX5rUVniSzdJfh9gN3UJKG5kZYRmJKiM3o7K0_LgYejrPVRis9Z5ojpDJP6Js\"}}" }

    context 'with valid data' do
      it 'saves subscription' do
        subject
        expect(client.reload.web_push_token).to eq JSON.parse("{\"endpoint\":\"https://updates.push.services.mozilla.com/wpush/v1/gAAAAABXl1UulZVga2J9KycmWioH5HbQrmD3f8yIxfE79GW5bh80G5Ndjm-XfJbSL9ekJ8QJ1fskCylQCfSLPvf7PlXb-W_OjC1dXqPMqK40VUFHsF8jADELInKVyifIORunYGtUBzvh\",\"keys\":{\"auth\":\"vJd60OQAvKNjDOFCQidYIA\",\"p256dh\":\"BKkAQRS74AUsuX3YfY60D7LSm1xX5rUVniSzdJfh9gN3UJKG5kZYRmJKiM3o7K0_LgYejrPVRis9Z5ojpDJP6Js\"}}").deep_symbolize_keys.to_s
        expect(client.reload.web_push_browser).to eq('firefox')
        expect(client.reload.web_push_enabled).to be_truthy
      end
    end

    context 'with invalid data' do

      it 'doesnt have token' do
        post :create, shop_id: shop.uniqid, ssid: session.code
        expect(client.reload.web_push_enabled).to eq(nil)
      end

    end

  end

end
