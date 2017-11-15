require 'rails_helper'

describe TriggerMailings::Triggers::AbandonedCategory do


  describe '.condition_happened?' do

    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user) }
    let!(:user_old) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:client) { create(:client, user: user, shop: shop) }

    let!(:item_category) { create(:item_category, shop: shop) }
    let!(:item_1) { create(:item, shop: shop, is_available: true, sales_rate: 100, category_ids: [item_category.external_id]) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, sales_rate: 100, category_ids: [item_category.external_id]) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, sales_rate: nil, category_ids: [item_category.external_id]) }
    let!(:order) { create(:order, user: user, date: 8.days.ago, shop: shop)}

    let!(:action) { create(:action_cl, session: user.sessions.first, shop: shop, object_type: 'Item', event: 'view', object_id: item_1.uniqid, date: 72.hours.ago.to_date, created_at: 72.hours.ago) }
    let!(:action_category) { create(:action_cl, session: user.sessions.first, shop: shop, object_type: 'ItemCategory', object_id: item_category.external_id, event: 'view', date: 3.hour.ago.to_date, created_at: 3.hour.ago) }


    subject { TriggerMailings::Triggers::AbandonedCategory.new client  }


    context 'happened' do
      it {
        expect( subject.condition_happened? ).to be_truthy
      }
    end

    context 'not happened if have recently order' do
      it {
        order.update! date: 5.days.ago
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened there was no action in time range' do
      let!(:action) { create(:action_cl, session: user.sessions.first, shop: shop, object_type: 'Item', event: 'view', object_id: item_1.uniqid, date: 3.hours.ago.to_date, created_at: 3.hours.ago) }
      it {
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened there was no category subscription' do
      let!(:action_category) { create(:action_cl, session: user.sessions.first, shop: shop, object_type: 'ItemCategory', object_id: item_category.external_id, event: 'view', date: 5.days.ago.to_date, created_at: 5.days.ago) }
      it {
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened there was order in control period' do
      it {
        order.update! date: 47.hours.ago
        expect( subject.condition_happened? ).to be_falsey
      }
    end

    context 'not happened there was no item category found' do
      it {
        item_category.destroy
        expect( subject.condition_happened? ).to be_falsey
      }
    end

  end


  describe '.recommended_ids' do

    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user) }
    let!(:user_old) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:client) { create(:client, user: user, shop: shop) }

    let!(:item_category) { create(:item_category, shop: shop) }
    let!(:item_1) { create(:item, shop: shop, is_available: true, widgetable: true, sales_rate: 100, category_ids: [item_category.external_id]) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, widgetable: true, sales_rate: 100, category_ids: [item_category.external_id]) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, widgetable: true, sales_rate: nil, category_ids: [item_category.external_id]) }

    let!(:action) { create(:action_cl, session: user.sessions.first, shop: shop, object_type: 'Item', event: 'view', object_id: item_1.uniqid, date: 72.hours.ago.to_date, created_at: 72.hours.ago) }
    let!(:action_category) { create(:action_cl, session: user.sessions.first, shop: shop, object_type: 'ItemCategory', object_id: item_category.external_id, event: 'view', date: 3.hour.ago.to_date, created_at: 3.hour.ago) }

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'abandoned_category', subject: 'haha', liquid_template: '^{% tablerow item in recommended_items cols:3 %}{{ item.id }} {% endtablerow %}', enabled: true) }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com') }

    subject { TriggerMailings::Triggers::AbandonedCategory.new client  }

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
