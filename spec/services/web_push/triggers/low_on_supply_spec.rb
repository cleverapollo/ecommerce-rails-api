require 'rails_helper'

describe WebPush::Triggers::LowOnSupply do

  let!(:user) { create(:user) }
  let!(:shop) { create(:shop) }
  let!(:client) { create(:client, user: user, shop: shop, web_push_token: {a: true}, web_push_browser: 'chrome' ) }

  let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
  let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: false) }
  let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: false) }
  let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
  let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
  let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }

  let!(:action) { create(:action, shop: shop, user: user, item: item_1) }

  let!(:order_1) { create(:order, user: user, shop: shop, date: 4.weeks.ago)}
  let!(:order_2) { create(:order, user: user, shop: shop, date: 3.weeks.ago)}
  let!(:order_3) { create(:order, user: user, shop: shop, date: 2.weeks.ago)}
  let!(:order_4) { create(:order, user: user, shop: shop, date: 1.week.ago)}

  let!(:order_item_1) { create(:order_item, order: order_1, shop: shop, action: action, item: item_1 )}
  let!(:order_item_2) { create(:order_item, order: order_1, shop: shop, action: action, item: item_2 )}
  let!(:order_item_3) { create(:order_item, order: order_1, shop: shop, action: action, item: item_4 )}
  let!(:order_item_4) { create(:order_item, order: order_2, shop: shop, action: action, item: item_1 )}
  let!(:order_item_5) { create(:order_item, order: order_2, shop: shop, action: action, item: item_2 )}
  let!(:order_item_6) { create(:order_item, order: order_3, shop: shop, action: action, item: item_4 )}
  let!(:order_item_7) { create(:order_item, order: order_4, shop: shop, action: action, item: item_1 )}
  let!(:order_item_8) { create(:order_item, order: order_4, shop: shop, action: action, item: item_4 )}
  

  let!(:web_push_subscriptions_settings) { create(:web_push_subscriptions_settings, shop: shop) }
  let!(:web_push_trigger) { create(:web_push_trigger, shop: shop, trigger_type: 'low_on_supply', subject: 'test test test', message: 'test message for trigger', enabled: true ) }




  describe '.condition_happened?' do

    subject { WebPush::Triggers::LowOnSupply.new(client) }

    it 'happens' do
      trigger = subject
      expect( trigger.condition_happened? ).to be_truthy
      expect( trigger.items.count ).to eq 1
    end

  end




  describe 'common methods' do

    subject { WebPush::Triggers::LowOnSupply.new(client) }

    it '.code' do
      expect(WebPush::Triggers::LowOnSupply.code).to eq 'LowOnSupply'
      expect(subject.code).to eq 'LowOnSupply'
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
