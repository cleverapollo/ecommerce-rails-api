require 'rails_helper'

describe WebPush::Triggers::Retention do

  let!(:user) { create(:user) }
  let!(:shop) { create(:shop) }
  let!(:client) { create(:client, user: user, shop: shop, web_push_token: {a: true}, web_push_browser: 'chrome' ) }

  let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
  let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
  let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
  let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
  let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
  let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }

  let!(:action) { create(:action, shop: shop, user: user, item: item_1, timestamp: 1.month.ago.to_i) }

  let!(:web_push_subscriptions_settings) { create(:web_push_subscriptions_settings, shop: shop) }
  let!(:web_push_trigger) { create(:web_push_trigger, shop: shop, trigger_type: 'retention', subject: 'test test test', message: 'test message for trigger', enabled: true ) }


  describe '.condition_happened?' do

    subject { WebPush::Triggers::Retention.new(client) }

    context 'everything is correct' do

      it 'happens' do
        trigger = subject
        expect( trigger.condition_happened? ).to be_truthy
        expect( trigger.items.count ).to eq 1
      end

    end

    context 'not happened if there was actions earlier than 1 month' do
      let!(:action_1) { create(:action, shop: shop, user: user, item: item_2, timestamp: 1.day.ago.to_i) }
      it {
        expect( subject.condition_happened? ).to be_falsey
      }
    end

  end




  describe 'common methods' do

    subject { WebPush::Triggers::Retention.new(client) }

    it '.code' do
      expect(WebPush::Triggers::Retention.code).to eq 'Retention'
      expect(subject.code).to eq 'Retention'
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
