require 'rails_helper'

describe TriggerMailings::Triggers::ProductAvailable do


  describe '.condition_happened?' do

    let!(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:client) { create(:client, :with_email, user: user, shop: shop) }

    let!(:item) { create(:item, shop: shop, is_available: true, sales_rate: 100, price: 90, category_ids: ['1']) }

    let!(:subscribe_for_product_available) { create(:subscribe_for_product_available, user: user, shop: shop, item: item, subscribed_at: 10.hours.ago) }


    subject { TriggerMailings::Triggers::ProductAvailable.new client  }


    context 'happened' do
      it {
        expect( subject.condition_happened? ).to be_truthy
      }
    end

    context 'not happened there was no subscription' do
      it {
        subscribe_for_product_available.update! subscribed_at: 7.months.ago
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

  end


  describe '.recommended_ids' do

    let!(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:client) { create(:client, :with_email, user: user, shop: shop) }

    let!(:item) { create(:item, shop: shop, is_available: true, sales_rate: 100, price: 90, category_ids: ['1'], url: '', widgetable: true) }
    let!(:item_1) { create(:item, shop: shop, is_available: true, sales_rate: 100, price: 90, category_ids: ['1'], url: '', widgetable: true) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, sales_rate: 100, price: 90, category_ids: ['1'], url: '', widgetable: true) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, sales_rate: nil, price: 90, category_ids: ['1'], url: '', widgetable: true) }

    let!(:subscribe_for_product_available) { create(:subscribe_for_product_available, user: user, shop: shop, item: item, subscribed_at: 10.hours.ago) }

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'product_available', subject: 'haha', liquid_template: '^{% tablerow item in recommended_items cols:3 %}{{ item.id }} {% endtablerow %}', enabled: true) }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com') }


    subject { TriggerMailings::Triggers::ProductAvailable.new client  }

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
