require 'rails_helper'

describe WebPush::TriggerDetector do

  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:shop) { create(:shop) }
  let!(:client) { create(:client, user: user, shop: shop, last_web_push_sent_at: 26.hours.ago ) }
  let!(:web_push_token) { create(:web_push_token, client: client, token: {token: '123', browser: 'chrome'}) }

  let!(:web_push_subscriptions_settings)  { create(:web_push_subscriptions_settings, shop: shop) }

  let!(:trigger_abandoned_cart)           { create(:web_push_trigger, shop: shop, trigger_type: 'abandoned_cart', subject: 'test test test', message: 'test message for trigger', enabled: true ) }
  let!(:trigger_second_abandoned_cart)    { create(:web_push_trigger, shop: shop, trigger_type: 'second_abandoned_cart', subject: 'test test test', message: 'test message for trigger', enabled: true ) }
  let!(:trigger_product_available)        { create(:web_push_trigger, shop: shop, trigger_type: 'product_available', subject: 'test test test', message: 'test message for trigger', enabled: true ) }
  let!(:trigger_product_price_decrease)   { create(:web_push_trigger, shop: shop, trigger_type: 'product_price_decrease', subject: 'test test test', message: 'test message for trigger', enabled: true ) }
  let!(:trigger_retention)                { create(:web_push_trigger, shop: shop, trigger_type: 'retention', subject: 'test test test', message: 'test message for trigger', enabled: true ) }
  let!(:trigger_low_on_supply)            { create(:web_push_trigger, shop: shop, trigger_type: 'low_on_supply', subject: 'test test test', message: 'test message for trigger', enabled: true ) }

  let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, price: 200, is_fmcg: true, fmcg_periodic: true) }
  let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, price: 200, is_fmcg: true, fmcg_periodic: false) }
  let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, price: 200, is_fmcg: true, fmcg_periodic: false) }
  let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, price: 200, is_cosmetic: true, cosmetic_periodic: true) }
  let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, price: 200, is_cosmetic: true, cosmetic_periodic: true) }
  let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, price: 200, is_cosmetic: true, cosmetic_periodic: true) }

  # For AbandonedCart
  let!(:action_1) { create(:action_cl, shop: shop, session: session, object_type: 'Item', object_id: item_3.uniqid, event: 'cart', date: 2.hours.ago.to_date, created_at: 2.hours.ago) }

  # For SecondAbandonedCart
  let!(:action_2) { create(:action_cl, shop: shop, session: session, object_type: 'Item', object_id: item_4.uniqid, event: 'cart', date: 26.hours.ago.to_date, created_at: 26.hours.ago) }
  let!(:web_push_trigger_message_2) { create(:web_push_trigger_message, shop: shop, clicked: false, web_push_trigger: trigger_abandoned_cart, created_at: 26.hours.ago, client: client, trigger_data: {test: 'test'} ) }

  # For ProductAvailable
  let!(:subscribe_for_product_available) { create(:subscribe_for_product_available, user: user, shop: shop, item: item_5, subscribed_at: 10.hours.ago) }

  # For ProductPriceDecrease
  let!(:subscribe_for_product_price) { create(:subscribe_for_product_price, user: user, shop: shop, item: item_6, subscribed_at: 10.hours.ago, price: 700) }

  # For Retention
  let!(:action_4) { create(:action_cl, shop: shop, session: session, object_type: 'Item', object_id: item_5.uniqid, event: 'view', date: 1.month.ago.to_date, created_at: 1.month.ago) }

  # For LowOnSupply
  let!(:action_3) { create(:action_cl, shop: shop, session: session, object_type: 'Item', object_id: item_1.uniqid, event: 'view') }
  let!(:order_1) { create(:order, user: user, shop: shop, date: 4.weeks.ago)}
  let!(:order_2) { create(:order, user: user, shop: shop, date: 3.weeks.ago)}
  let!(:order_3) { create(:order, user: user, shop: shop, date: 2.weeks.ago)}
  let!(:order_4) { create(:order, user: user, shop: shop, date: 1.week.ago)}
  let!(:order_item_1) { create(:order_item, order: order_1, shop: shop, item: item_1 )}
  let!(:order_item_2) { create(:order_item, order: order_1, shop: shop, item: item_2 )}
  let!(:order_item_3) { create(:order_item, order: order_1, shop: shop, item: item_4 )}
  let!(:order_item_4) { create(:order_item, order: order_2, shop: shop, item: item_1 )}
  let!(:order_item_5) { create(:order_item, order: order_2, shop: shop, item: item_2 )}
  let!(:order_item_6) { create(:order_item, order: order_3, shop: shop, item: item_4 )}
  let!(:order_item_7) { create(:order_item, order: order_4, shop: shop, item: item_1 )}
  let!(:order_item_8) { create(:order_item, order: order_4, shop: shop, item: item_4 )}


  describe 'determine correct priority' do

    subject { WebPush::TriggerDetector.new(shop).detect(client) }

    context 'for second abandoned cart' do
      it 'it returns second abandoned cart' do
        expect(subject.class.name).to eq 'WebPush::Triggers::SecondAbandonedCart'
      end
    end

    context 'for low on supply' do
      it 'it returns low on supply' do
        web_push_trigger_message_2.destroy
        expect(subject.class.name).to eq 'WebPush::Triggers::LowOnSupply'
      end
    end

    context 'for abandoned cart' do
      let!(:client_cart) { create(:client_cart, user: user, shop: shop, items: [item_3.id]) }
      it 'it returns abandoned cart' do
        web_push_trigger_message_2.destroy
        order_1.destroy
        order_2.destroy
        order_3.destroy
        order_4.destroy
        expect(subject.class.name).to eq 'WebPush::Triggers::AbandonedCart'
      end
    end

    context 'for product available' do
      let!(:action_1) { }
      it 'it returns product available' do
        web_push_trigger_message_2.destroy
        order_1.destroy
        order_2.destroy
        order_3.destroy
        order_4.destroy
        expect(subject.class.name).to eq 'WebPush::Triggers::ProductAvailable'
      end
    end

    context 'for product price decrease' do
      let!(:action_1) { }
      it 'it returns product price decrease' do
        web_push_trigger_message_2.destroy
        order_1.destroy
        order_2.destroy
        order_3.destroy
        order_4.destroy
        subscribe_for_product_available.destroy
        expect(subject.class.name).to eq 'WebPush::Triggers::ProductPriceDecrease'
      end
    end

    context 'for retention' do
      let!(:action_1) { }
      let!(:action_2) { }
      let!(:action_3) { }
      it 'it returns retention' do
        web_push_trigger_message_2.destroy
        order_1.destroy
        order_2.destroy
        order_3.destroy
        order_4.destroy
        subscribe_for_product_available.destroy
        subscribe_for_product_price.destroy
        expect(subject.class.name).to eq 'WebPush::Triggers::Retention'
      end
    end



  end

end
