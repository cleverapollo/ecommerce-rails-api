require 'rails_helper'

describe TriggerMailings::Triggers::AbandonedCart do


  describe '.condition_happened?' do

    let!(:user) { create(:user) }
    let!(:shop) { create(:shop) }
    let!(:client) { create(:client, user: user, shop: shop, email: 'test@rees46demo.com') }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }

    let!(:action) { create(:action, shop: shop, user: user, item: item_1, rating: Actions::Cart::RATING, cart_date: 2.hours.ago, cart_count: 2) }

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'abandoned_cart', subject: 'haha', enabled: true) }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com', template_type: MailingsSettings::TEMPLATE_LIQUID) }

    subject { TriggerMailings::Triggers::AbandonedCart.new(client) }

    context 'default checks' do

      it 'happens' do
        trigger = subject
        expect( trigger.condition_happened? ).to be_truthy
        expect( trigger.source_items.count ).to eq(1)
        expect( trigger.source_items.first.amount ).to eq(2)
      end

    end

  end


  describe '.recommended_ids' do

    let!(:user) { create(:user) }
    let!(:shop) { create(:shop) }
    let!(:client) { create(:client, user: user, shop: shop, email: 'test@rees46demo.com') }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }

    let!(:action) { create(:action, shop: shop, user: user, item: item_1, rating: Actions::Cart::RATING, cart_date: 2.hours.ago, cart_count: 2) }

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'abandoned_cart', subject: 'haha', enabled: true) }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com', template_type: MailingsSettings::TEMPLATE_LIQUID) }

    subject { TriggerMailings::Triggers::AbandonedCart.new client  }

    context 'returns recommendations' do

      it {
        trigger = subject
        trigger.triggered?
        expect( trigger.recommendations(10).any? ).to be_truthy
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
