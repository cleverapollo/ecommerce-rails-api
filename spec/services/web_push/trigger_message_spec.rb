require 'rails_helper'

describe WebPush::TriggerMessage do

  let!(:user) { create(:user) }
  let!(:shop) { create(:shop, web_push_balance: 1) }
  let!(:client) { create(:client, user: user, shop: shop, web_push_enabled: true) }
  let!(:web_push_token) { create(:web_push_token, client: client, token: {token: '123', browser: 'chrome'}) }

  let!(:web_push_subscriptions_settings)  { create(:web_push_subscriptions_settings, shop: shop) }
  let!(:web_push_trigger) { create(:web_push_trigger, shop: shop, trigger_type: 'abandoned_cart', subject: 'test test test', message: 'test message for trigger', enabled: true ) }
  let!(:item) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
  let!(:action) { create(:action, shop: shop, user: user, item: item, rating: Actions::Cart::RATING, cart_date: 2.hours.ago, cart_count: 2) }

  before { allow_any_instance_of(WebPushToken).to receive(:send_web_push).and_return(true) }

  describe 'body generation' do

    it 'generates correct body' do
      trigger = WebPush::TriggerDetector.new(shop).detect(client)
      message = WebPush::TriggerMessage.new trigger, client
      expect(message.client).to eq client
      expect(message.shop).to eq shop
      expect(message.trigger).to eq trigger
      expect(message.message.web_push_trigger_id).to eq web_push_trigger.id
      expect(message.message.code).to eq WebPushTriggerMessage.first.code
      expect(message.body[:title]).to eq trigger.settings[:subject]
      expect(message.body[:body]).to eq trigger.settings[:message]
    end

    it 'send message and reduce balance' do
      trigger = WebPush::TriggerDetector.new(shop).detect(client)
      message = WebPush::TriggerMessage.new trigger, client
      message.send
      expect(shop.reload.web_push_balance).to eq(0)
    end

  end

end