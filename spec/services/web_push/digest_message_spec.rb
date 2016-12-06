require 'rails_helper'

describe WebPush::DigestMessage do

  let!(:user) { create(:user) }
  let!(:shop) { create(:shop, web_push_balance: 1) }
  let!(:client) { create(:client, user: user, shop: shop, web_push_enabled: true) }
  let!(:web_push_token) { create(:web_push_token, client: client, token: {token: '123', browser: 'chrome'}) }

  let!(:web_push_subscriptions_settings)  { create(:web_push_subscriptions_settings, shop: shop) }
  let!(:web_push_digest) { create(:web_push_digest, shop: shop, subject: 'test test test', message: 'test message for trigger', url: 'http://rees46.com',  ) }
  let!(:web_push_digest_batch) { create(:web_push_digest_batch, shop: shop, mailing: web_push_digest, start_id: client.id, end_id: client.id + 1 ) }

  describe 'body generation' do

    it 'generates correct body' do
      message = WebPush::DigestMessage.new client, web_push_digest, web_push_digest_batch
      expect(message.client).to eq client
      expect(message.shop).to eq shop
      expect(message.message.web_push_digest_id).to eq web_push_digest.id
      expect(message.message.web_push_digest_batch_id).to eq web_push_digest_batch.id
      expect(message.message.code).to eq WebPushDigestMessage.first.code
      expect(message.body[:title]).to eq web_push_digest.subject
      expect(message.body[:body]).to eq web_push_digest.message
      expect(message.body[:icon]).to eq web_push_digest.fetch_picture_url
      expect(message.body[:url].scan('utm_source=rees46').any?).to be_truthy
      expect(message.body[:url].scan('utm_medium=web_push_digest').any?).to be_truthy
      expect(message.body[:url].scan('recommended_by=web_push_digest').any?).to be_truthy
      expect(message.body[:url].scan("rees46_web_push_digest_code=#{WebPushDigestMessage.first.code}").any?).to be_truthy
      expect(message.body[:url].scan(web_push_digest.url).any?).to be_truthy
    end

  end

  describe 'reduce balance' do
    before { allow_any_instance_of(WebPushToken).to receive(:send_web_push).and_return(true) }

    it 'send message' do
      message = WebPush::DigestMessage.new client, web_push_digest, web_push_digest_batch
      message.send
      expect(shop.reload.web_push_balance).to eq(0)
      expect(shop.web_push_digest_messages.count).to eq(1)
    end
  end

  describe 'invalid tokens' do
    before { allow_any_instance_of(WebPushToken).to receive(:send_web_push).and_raise(Webpush::InvalidSubscription) }

    it 'send message' do
      message = WebPush::DigestMessage.new client, web_push_digest, web_push_digest_batch
      message.send
      expect(shop.reload.web_push_balance).to eq(1)
      expect(shop.web_push_digest_messages.count).to eq(0)
      expect(client.reload.web_push_enabled).to eq(false)
    end
  end

end