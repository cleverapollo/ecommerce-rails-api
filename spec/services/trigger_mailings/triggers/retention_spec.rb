require 'rails_helper'

describe TriggerMailings::Triggers::Retention do


  describe '.condition_happened?' do

    let!(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer, supply_available: true) }
    let!(:client) { create(:client, user: user, shop: shop) }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }

    let!(:action) { create(:action, shop: shop, user: user, item: item_1, timestamp: 1.month.ago.to_i) }


    subject { TriggerMailings::Triggers::Retention.new client  }


    context 'happened' do

      it {
        expect( subject.condition_happened? ).to be_truthy
      }

    end

    context 'not happened if there was actions earlier than 1 month' do
      let!(:action_1) { create(:action, shop: shop, user: user, item: item_2, timestamp: 1.day.ago.to_i) }
      it {
        expect( subject.condition_happened? ).to be_falsey
      }
    end

  end


  describe '.recommended_ids' do

    let!(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:client) { create(:client, user: user, shop: shop) }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_7) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_8) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_9) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_10) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_11) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_12) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }
    let!(:item_13) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true) }

    let!(:action) { create(:action, shop: shop, user: user, item: item_1, timestamp: 1.month.ago.to_i) }

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'retention', subject: 'haha', liquid_template: '^{% tablerow item in recommended_items cols:3 %}{{ item.url }}{% endtablerow %}', enabled: true) }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com') }

    subject { TriggerMailings::Triggers::Retention.new client  }

    context 'returns recommendations' do
      it {
        expect( subject.recommendations(10).any? ).to be_truthy
      }
    end

    context 'generates html' do
      it {
        trigger = subject
        trigger.triggered?
        letter = TriggerMailings::Letter.new(client, trigger)
        expect( letter.trigger_mail.present? ).to be_truthy
      }
    end

  end

end
