require 'rails_helper'

describe TriggerMailings::Triggers::RecentlyPurchased do


  describe '.condition_happened?' do

    let!(:user) { create(:user) }
    let!(:shop) { create(:shop, ekomi_enabled: true, ekomi_id: '665', ekomi_key: 'FMJuyuC8uEbo3WxRa5aG') }
    let!(:client) { create(:client, user: user, shop: shop, email: 'test@example.com') }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }

    let!(:action) { create(:action, shop: shop, user: user, item: item_1) }

    let!(:order_1) { create(:order, user: user, shop: shop, date: 7.days.ago)}
    let!(:order_2) { create(:order, user: user, shop: shop, date: 10.weeks.ago)}

    let!(:order_item_1) { create(:order_item, order: order_1, shop: shop, action: action, item: item_1 )}
    let!(:order_item_2) { create(:order_item, order: order_1, shop: shop, action: action, item: item_2 )}
    let!(:order_item_3) { create(:order_item, order: order_1, shop: shop, action: action, item: item_4 )}
    let!(:order_item_4) { create(:order_item, order: order_2, shop: shop, action: action, item: item_1 )}
    let!(:order_item_5) { create(:order_item, order: order_2, shop: shop, action: action, item: item_2 )}

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'recently_purchased', subject: 'haha', template: '{{ source_item }}{{ source_item }}{{ source_item }}{{ recommended_item }}{{ recommended_item }}{{ recommended_item }}{{ feedback_button_link }}', item_template: '{{ url }}{{ image_url }}{{ description }}{{ currency }}{{ price }}', enabled: true, source_item_template: '{{ url }}{{ name }}{{ image_url }}{{ price }}') }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com') }

    subject { TriggerMailings::Triggers::RecentlyPurchased.new(client) }


    context 'default checks' do

      it {
        expect( subject.condition_happened? ).to be_truthy
      }

    end

    context 'ekomi integration' do
      it {
        trigger = subject
        expect( trigger.triggered? ).to be_truthy
        letter = TriggerMailings::Letter.new(client, trigger)
        raise letter.body.inspect
        expect( letter.body.scan(/(feedback|opinion|kundenmeinung)\.php/).any? ).to be_truthy
      }
    end


    context 'when trigger disabled for shop' do

    end

  end


  describe '.recommended_ids' do

    let!(:user) { create(:user) }
    let!(:shop) { create(:shop, supply_available: true) }
    let!(:client) { create(:client, user: user, shop: shop) }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: false) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: false) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_7) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_8) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_9) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_10) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_11) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_12) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_13) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }

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

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'recently_purchased', subject: 'haha', template: '{{ source_item }}{{ source_item }}{{ source_item }}{{ recommended_item }}{{ recommended_item }}{{ recommended_item }}', item_template: '{{ url }}{{ image_url }}{{ description }}{{ currency }}{{ price }}', enabled: true, source_item_template: '{{ url }}{{ name }}{{ image_url }}{{ price }}') }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com') }

    subject { TriggerMailings::Triggers::RecentlyPurchased.new client  }

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
