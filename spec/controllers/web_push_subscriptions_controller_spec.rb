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
      it 'saves subscription for chrome and firefox' do
        subject
        expect(client.reload.web_push_token).to eq JSON.parse("{\"endpoint\":\"https://updates.push.services.mozilla.com/wpush/v1/gAAAAABXl1UulZVga2J9KycmWioH5HbQrmD3f8yIxfE79GW5bh80G5Ndjm-XfJbSL9ekJ8QJ1fskCylQCfSLPvf7PlXb-W_OjC1dXqPMqK40VUFHsF8jADELInKVyifIORunYGtUBzvh\",\"keys\":{\"auth\":\"vJd60OQAvKNjDOFCQidYIA\",\"p256dh\":\"BKkAQRS74AUsuX3YfY60D7LSm1xX5rUVniSzdJfh9gN3UJKG5kZYRmJKiM3o7K0_LgYejrPVRis9Z5ojpDJP6Js\"}}").deep_symbolize_keys.to_s
        expect(client.reload.web_push_browser).to eq('firefox')
        expect(client.reload.web_push_enabled).to be_truthy
      end

      it 'saves subscription for safari' do
        post :create, shop_id: shop.uniqid, ssid: session.code, token: "{\"browser\":\"safari\",\"token\":\"CEB087ABF3D063CF0D316FA0E40B7C7FFA038C4D9A0CB995251366C3AFEF7345\"}"
        expect(client.reload.web_push_token).to eq JSON.parse("{\"browser\":\"safari\",\"token\":\"CEB087ABF3D063CF0D316FA0E40B7C7FFA038C4D9A0CB995251366C3AFEF7345\"}").deep_symbolize_keys.to_s
        expect(client.reload.web_push_browser).to eq('safari')
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

  describe 'POST safari_webpush' do
    let!(:shop) { create(:shop) }

    subject {  }

    context 'with valid data' do
      it 'log error' do
        post :safari_webpush, shop_id: shop.uniqid, type: '/v1/log'
        expect(response).to have_http_status(200)
      end

      it 'get token device' do
        post :safari_webpush, shop_id: shop.uniqid, type: '/v1/devices/CEB087ABF3D063CF0D316FA0E40B7C7FFA038C4D9A0CB995251366C3AFEF7345/registrations/web.com.rees46'
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)['token']).to eq('CEB087ABF3D063CF0D316FA0E40B7C7FFA038C4D9A0CB995251366C3AFEF7345')
      end
    end
  end

end
