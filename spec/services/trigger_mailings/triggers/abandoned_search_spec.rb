require 'rails_helper'

describe TriggerMailings::Triggers::AbandonedSearch do


  describe '.condition_happened?' do

    let!(:user) { create(:user) }
    let!(:user_old) { create(:user) }
    let!(:shop) { create(:shop) }
    let!(:client) { create(:client, user: user, shop: shop) }
    let!(:client_old) { create(:client, user: user_old, shop: shop) }

    let!(:item_1) { create(:item, shop: shop, is_available: true, sales_rate: 100) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, sales_rate: 100) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, sales_rate: nil) }

    let!(:action) { create(:action, user: user, shop: shop, item: item_1, timestamp: 3.hours.ago.to_i) }

    let!(:order_1) { create(:order, shop: shop, user: user_old, uniqid: '123', date: Date.current) }
    let!(:order_item_1_1) { create(:order_item, shop: shop, order: order_1, item: item_1, action: action) }
    let!(:order_item_1_2) { create(:order_item, shop: shop, order: order_1, item: item_2, action: action) }
    let!(:order_2) { create(:order, shop: shop, user: user_old, uniqid: '456', date: Date.current) }
    let!(:order_item_2_1) { create(:order_item, shop: shop, order: order_2, item: item_2, action: action) }
    let!(:order_item_2_2) { create(:order_item, shop: shop, order: order_2, item: item_3, action: action) }

    let!(:search_query) { create(:search_query, shop: shop, date: Date.current, user: user, query: '123123') }
    let!(:search_query_old) { create(:search_query, shop: shop, date: Date.current, user: user_old, query: '123123') }

    subject { TriggerMailings::Triggers::AbandonedSearch.new client  }


    context 'happened' do
      it {
        expect( subject.condition_happened? ).to be_truthy
      }
    end

    context 'not happened there was no action in time range' do
      it {
        action.update! timestamp: 72.hours.ago.to_i
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened there was no search query today' do
      it {
        search_query.update! date: 2.days.ago
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened there was no search query at all' do
      it {
        search_query.destroy
        expect( subject.condition_happened? ).to be_falsey
      }
    end

  end


  describe '.recommended_ids' do

    let!(:user) { create(:user) }
    let!(:user_old) { create(:user) }
    let!(:shop) { create(:shop) }
    let!(:client) { create(:client, user: user, shop: shop) }
    let!(:client_old) { create(:client, user: user_old, shop: shop) }

    let!(:item_1) { create(:item, shop: shop, is_available: true, sales_rate: 100, widgetable: true) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, sales_rate: 100, widgetable: true) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, sales_rate: nil, widgetable: true) }

    let!(:action) { create(:action, user: user, shop: shop, item: item_1, timestamp: 3.hours.ago.to_i) }

    let!(:order_1) { create(:order, shop: shop, user: user_old, uniqid: '123', date: Date.current) }
    let!(:order_item_1_1) { create(:order_item, shop: shop, order: order_1, item: item_1, action: action) }
    let!(:order_item_1_2) { create(:order_item, shop: shop, order: order_1, item: item_2, action: action) }
    let!(:order_2) { create(:order, shop: shop, user: user_old, uniqid: '456', date: Date.current) }
    let!(:order_item_2_1) { create(:order_item, shop: shop, order: order_2, item: item_2, action: action) }
    let!(:order_item_2_2) { create(:order_item, shop: shop, order: order_2, item: item_3, action: action) }

    let!(:search_query) { create(:search_query, shop: shop, date: Date.current, user: user, query: '123123') }
    let!(:search_query_old) { create(:search_query, shop: shop, date: Date.current, user: user_old, query: '123123') }

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'abandoned_search', subject: 'haha', liquid_template: '^{% tablerow item in recommended_items cols:3 %}{{ item.id }} {% endtablerow %}', enabled: true) }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com', template_type: MailingsSettings::TEMPLATE_LIQUID) }

    subject { TriggerMailings::Triggers::AbandonedSearch.new client  }

    context 'returns recommendations' do
      it {
        trigger = subject
        expect( trigger.triggered? ).to be_truthy
        expect( trigger.recommendations(10).any? ).to be_truthy
      }
    end

    context 'generates html' do
      it {
        trigger = subject
        trigger.triggered?
        letter = TriggerMailings::Letter.new(client, trigger)
        expect( letter.trigger_mail.present? ).to be_truthy
        expect( letter.trigger_mail.trigger_data.present? ).to be_truthy
      }
    end

  end

end