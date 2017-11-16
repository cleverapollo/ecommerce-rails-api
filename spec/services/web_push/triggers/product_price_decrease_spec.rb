require 'rails_helper'

describe WebPush::Triggers::ProductPriceDecrease do

  let!(:user) { create(:user) }
  let!(:shop) { create(:shop) }
  let!(:client) { create(:client, user: user, shop: shop ) }
  let!(:web_push_token) { create(:web_push_token, client: client, token: {token: '123', browser: 'chrome'}) }

  let!(:item) { create(:item, shop: shop, is_available: true, sales_rate: 100, price: 90, category_ids: ['1']) }
  let!(:subscribe_for_product_price) { create(:subscribe_for_product_price, user: user, shop: shop, item: item, subscribed_at: 10.hours.ago, price: 100) }
  let!(:web_push_subscriptions_settings) { create(:web_push_subscriptions_settings, shop: shop) }
  let!(:web_push_trigger) { create(:web_push_trigger, shop: shop, trigger_type: 'product_price_decrease', subject: 'test test test', message: 'test message for trigger', enabled: true ) }


  describe '.condition_happened?' do

    subject { WebPush::Triggers::ProductPriceDecrease.new(client) }

    context 'everything is correct' do

      it 'happens' do
        trigger = subject
        expect( trigger.condition_happened? ).to be_truthy
        expect( trigger.items.count ).to eq 1
        expect( trigger.items.first ).to eq item
      end

    end

    context 'not happened there was no subscription' do
      it {
        subscribe_for_product_price.update! subscribed_at: 7.months.ago
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened there was order with this item' do
      let!(:order) { create(:order, user: user, date: 7.months.ago, shop: shop)}
      let!(:order_item) { create(:order_item, order: order, shop: shop, item: item)}
      it {
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened there was no item found' do
      it {
        item.destroy
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened when price is not significally different' do
      it {
        item.update price: subscribe_for_product_price.price * 0.999
        expect( subject.condition_happened? ).to be_falsey
      }
    end

  end




  describe 'common methods' do

    subject { WebPush::Triggers::ProductPriceDecrease.new(client) }

    it '.code' do
      expect(WebPush::Triggers::ProductPriceDecrease.code).to eq 'ProductPriceDecrease'
      expect(subject.code).to eq 'ProductPriceDecrease'
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
