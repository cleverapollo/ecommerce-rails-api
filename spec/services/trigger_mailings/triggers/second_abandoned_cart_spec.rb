require 'rails_helper'

describe TriggerMailings::Triggers::SecondAbandonedCart do

  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:client) { create(:client, user: user, shop: shop, email: 'test@rees46demo.com', last_trigger_mail_sent_at: 25.hours.ago) }

  let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }

  let!(:client_cart) { create(:client_cart, shop: shop, user: user, items: [item_1.id]) }

  let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'abandoned_cart', subject: 'haha', enabled: true) }
  let!(:trigger_mail) { create(:trigger_mail, shop: shop, opened: false, created_at: 25.hours.ago, trigger_mailing_id: trigger_mailing.id, client: client) }

  subject { TriggerMailings::Triggers::SecondAbandonedCart.new(client) }

  context 'default checks' do

    it 'happens' do
      trigger = subject
      expect( trigger.condition_happened? ).to be_truthy
      expect( trigger.source_items.count ).to eq(1)
    end

  end
end
