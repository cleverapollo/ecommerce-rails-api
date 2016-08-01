require 'rails_helper'

describe WebPush::Triggers::AbandonedCart do

  let!(:user) { create(:user) }
  let!(:shop) { create(:shop) }
  let!(:client) { create(:client, user: user, shop: shop, web_push_token: {a: true}, web_push_browser: 'chrome' ) }

  let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
  let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
  let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
  let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
  let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
  let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }

  let!(:action) { create(:action, shop: shop, user: user, item: item_1, rating: Actions::Cart::RATING, cart_date: 2.hours.ago, cart_count: 2) }

  let!(:web_push_subscriptions_settings) { create(:web_push_subscriptions_settings, shop: shop) }
  let!(:web_push_trigger) { create(:web_push_trigger, shop: shop, trigger_type: 'abandoned_cart', subject: 'test test test', message: 'test message for trigger', enabled: true ) }




  describe '.condition_happened?' do

    subject { WebPush::Triggers::AbandonedCart.new(client) }

    it 'happens' do
      trigger = subject
      expect( trigger.condition_happened? ).to be_truthy
      expect( trigger.items.count ).to eq 1
      expect( trigger.items.first ).to eq item_1
      expect( trigger.items.first.amount ).to eq 2
    end

  end




  describe 'common methods' do

    subject { WebPush::Triggers::AbandonedCart.new(client) }

    it '.code' do
      expect(WebPush::Triggers::AbandonedCart.code).to eq 'AbandonedCart'
      expect(subject.code).to eq 'AbandonedCart'
    end

    it '.mailing' do
      expect(subject.mailing).to eq web_push_trigger
    end

    it '.settings' do
      expect(subject.settings[:subject]).to eq web_push_trigger.subject
      expect(subject.settings[:message]).to eq web_push_trigger.message
    end

  end



end