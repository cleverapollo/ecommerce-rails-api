require 'rails_helper'

describe TriggerMailings::Triggers::LowOnSupply do


  describe '.condition_happened?' do

    let!(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer, supply_available: true) }
    let!(:client) { create(:client, user: user, shop: shop) }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: false) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: false) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }


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

    subject { TriggerMailings::Triggers::LowOnSupply.new client  }


    context 'when have history with periodic products' do

      it {
        expect( subject.condition_happened? ).to be_truthy
      }

    end

    context 'when trigger sent recently' do

    end


    context 'when trigger disabled for shop' do

    end

  end


  describe '.recommended_ids' do

    let!(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:shop) { create(:shop, customer: customer, supply_available: true) }
    let!(:client) { create(:client, user: user, shop: shop) }

    let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: false) }
    let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: false) }
    let!(:item_4) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_5) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_6) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_fmcg: true, fmcg_periodic: true) }
    let!(:item_7) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
    let!(:item_8) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
    let!(:item_9) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
    let!(:item_10) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
    let!(:item_11) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
    let!(:item_12) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }
    let!(:item_13) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: true) }


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

    let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'low_on_supply', subject: 'haha', enabled: true) }
    let!(:mailings_settings) { create(:mailings_settings, shop: shop, send_from: 'test@rees46.com') }

    subject { TriggerMailings::Triggers::LowOnSupply.new client  }

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
