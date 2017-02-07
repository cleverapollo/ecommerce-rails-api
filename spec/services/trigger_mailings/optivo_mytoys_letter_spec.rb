require 'rails_helper'

describe TriggerMailings::OptivoMytoysLetter do

  describe '.send' do

    let!(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer) }
    let!(:client) { create(:client, user: user, shop: shop, email: 'test@rees46demo.com') }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_7) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_8) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_9) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_10) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_11) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_12) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }

    let!(:action) { create(:action, shop: shop, user: user, item: item_1) }

    let!(:order_1) { create(:order, user: user, shop: shop, date: 7.days.ago)}
    let!(:order_2) { create(:order, user: user, shop: shop, date: 10.weeks.ago)}

    let!(:order_item_1) { create(:order_item, order: order_1, shop: shop, action: action, item: item_1 )}
    let!(:order_item_2) { create(:order_item, order: order_1, shop: shop, action: action, item: item_2 )}
    let!(:order_item_3) { create(:order_item, order: order_1, shop: shop, action: action, item: item_4 )}
    let!(:order_item_4) { create(:order_item, order: order_2, shop: shop, action: action, item: item_1 )}
    let!(:order_item_5) { create(:order_item, order: order_2, shop: shop, action: action, item: item_2 )}

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'recently_purchased', subject: 'haha', enabled: true) }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com') }

    subject { TriggerMailings::Triggers::RecentlyPurchased.new(client) }

    context 'creates trigger mail' do
      it {
        trigger = subject
        expect( trigger.triggered? ).to be_truthy
        expect{ TriggerMailings::OptivoMytoysLetter.new(client, trigger).send }.to change(TriggerMailingQueue, :count).by(1)
        expect( TriggerMailingQueue.count ).to eq(1)
        letter = TriggerMailingQueue.first
        expect(letter.recommended_items.any?).to be_truthy
        expect(letter.source_items.any?).to be_truthy
        expect(letter.trigger_type).to eq("recently_purchased")
        expect(letter.user_id).to eq(client.user_id)
        expect(letter.shop_id).to eq(shop.id)
        expect(letter.email).to eq(client.email)
        expect(letter.trigger_mail_code.present?).to be_truthy
        expect(letter.triggered_at >= 5.minutes.ago).to be_truthy
      }
    end
  end

  describe '.sync' do
    # let!(:user) { create(:user) }
    # let!(:shop) { create(:shop) }
    # let!(:client) { create(:client, user: user, shop: shop) }
    let!(:trigger_mailing_queue_1) { create(:trigger_mailing_queue, recommended_items: [1,2,3], triggered_at: 1.minute.ago, trigger_mail_code: '123')}
    let!(:trigger_mailing_queue_2) { create(:trigger_mailing_queue, recommended_items: [1,2,3], triggered_at: 2.minutes.ago, trigger_mail_code: '123')}
    let!(:trigger_mailing_queue_3) { create(:trigger_mailing_queue, recommended_items: [1,2,3], triggered_at: 3.minutes.ago, trigger_mail_code: '123')}
    let!(:trigger_mailing_queue_4) { create(:trigger_mailing_queue, recommended_items: [1,2,3], triggered_at: 4.minutes.ago, trigger_mail_code: '123')}
    subject { TriggerMailings::OptivoMytoysLetter.sync }
    it {
      expect{subject}.to change(TriggerMailingQueue, :count).to(0)
    }
  end

end
