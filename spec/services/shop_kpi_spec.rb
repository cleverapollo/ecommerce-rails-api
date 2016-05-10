require 'rails_helper'

describe ShopKPI do

  let!(:user) { create(:user) }
  let!(:user_2) { create(:user) }
  let!(:user_3) { create(:user) }


  let!(:shop) { create(:shop) }

  let!(:client) {create(:client, user: user, shop: shop, subscription_popup_showed: true, accepted_subscription: true)}

  let!(:item_1) { create(:item, shop: shop, price: 100) }
  let!(:item_2) { create(:item, shop: shop, price: 200) }

  let!(:action_1) { create(:action, shop: shop, item: item_1, user: user, rating: 4.2, timestamp: (Date.yesterday + 2.hours).to_i) }
  let!(:action_2) { create(:action, shop: shop, item: item_2, user: user, timestamp: (Date.yesterday + 2.hours).to_i, recommended_by: 'digest_mail') }
  let!(:action_3) { create(:action, shop: shop, item: item_2, user: user_2, rating: 4.2, timestamp: (Date.yesterday + 2.hours).to_i) }
  let!(:action_4) { create(:action, shop: shop, item: item_2, user: user_3, rating: 3.2, timestamp: (Date.yesterday + 2.hours).to_i) }
  let!(:action_5) { create(:action, shop: shop, item: item_1, user: user_3, rating: 3.2, timestamp: DateTime.current.to_i) }

  let!(:trigger_mailing_1) { create(:trigger_mailing, trigger_type: 'type_1', shop: shop, enabled: true) }
  let!(:trigger_mailing_2) { create(:trigger_mailing, trigger_type: 'type_2', shop: shop, enabled: true) }
  let!(:trigger_mailing_3) { create(:trigger_mailing, trigger_type: 'type_3', shop: shop, enabled: false) }
  let!(:trigger_mail_1) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_1, client: client, created_at: (Date.yesterday + 2.hours), clicked: true) }
  let!(:trigger_mail_2) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_1, client: client, created_at: (Date.yesterday + 2.hours)) }
  let!(:trigger_mail_3) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_2, client: client, created_at: (Date.yesterday + 2.hours)) }
  let!(:trigger_mail_4) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_2, client: client, created_at: (Date.yesterday + 2.hours)) }

  let!(:digest_mailing) { create(:digest_mailing, shop: shop) }
  let!(:digest_mailing_batch) { create(:digest_mailing_batch, mailing: digest_mailing, shop: shop) }

  let!(:digest_mail_1) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, clicked: true, created_at: (Date.yesterday + 2.hours)) }
  let!(:digest_mail_2) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: (Date.yesterday + 2.hours), clicked: true) }
  let!(:digest_mail_3) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: (Date.yesterday + 2.hours)) }
  let!(:digest_mail_4) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: (Date.yesterday + 2.hours), clicked: true) }

  let!(:order_1) { create(:order, user: user, uniqid: '1', shop: shop, value: 100, date: (Date.yesterday + 2.hours), source_id: trigger_mail_1.id, source_type: 'TriggerMail', recommended: true, common_value: 17, recommended_value: 24) }
  let!(:order_2) { create(:order, user: user, uniqid: '2', shop: shop, status: 1, value: 200, date: (Date.yesterday + 2.hours), source_id: digest_mail_1.id, source_type: 'DigestMail', recommended: false, common_value: 133, recommended_value: 13) }
  let!(:order_item_1) { create(:order_item, order: order_1, action: action_1, item: item_1, shop: shop, recommended_by: 'trigger_mail') }
  let!(:order_item_2) { create(:order_item, order: order_2, action: action_2, item: item_1, shop: shop, recommended_by: 'digest_mail') }

  let!(:interaction_1) { create(:interaction, item: item_1, shop: shop, user: user, code: 1, recommender_code: 2, created_at: (Date.yesterday + 2.hours)) }
  let!(:interaction_2) { create(:interaction, item: item_2, shop: shop, user: user, code: 1, created_at: (Date.yesterday + 2.hours)) }
  let!(:interaction_3) { create(:interaction, item: item_2, shop: shop, user: user, created_at: (Date.yesterday + 2.hours)) }
  let!(:interaction_4) { create(:interaction, item: item_1, shop: shop, user: user, code: 1, recommender_code: 2, created_at: 7.days.ago) }


  describe '.calculate' do

    subject { ShopKPI.new(shop).calculate_and_write_statistics_at(Date.yesterday) }

    it 'finds or initialize only one object per date' do
      expect{subject}.to change(ShopMetric, :count).from(0).to(1)
      subject
      expect(ShopMetric.count).to eq(1)
    end

    it 'calculates correct without tracking orders status' do
      subject
      shop_metric = ShopMetric.first
      expect(shop_metric.orders).to eq(2)
      expect(shop_metric.real_orders).to eq(1)
      expect(shop_metric.revenue).to eq(300)
      expect(shop_metric.real_revenue).to eq(200)
      expect(shop_metric.visitors).to eq(3)
      expect(shop_metric.products_viewed).to eq(4)

      expect(shop_metric.orders_original_count).to eq(1)
      expect(shop_metric.orders_recommended_count).to eq(1)
      expect(shop_metric.orders_original_revenue).to eq(150)
      expect(shop_metric.orders_recommended_revenue).to eq(37)

      expect(shop_metric.abandoned_products).to eq(2)
      expect(shop_metric.abandoned_money).to eq(300)


      expect(shop_metric.triggers_enabled_count).to eq(2)
      expect(shop_metric.triggers_sent).to eq(4)
      expect(shop_metric.triggers_clicked).to eq(1)
      expect(shop_metric.triggers_orders).to eq(1)
      expect(shop_metric.triggers_revenue).to eq(100)
      expect(shop_metric.triggers_orders_real).to eq(0)
      expect(shop_metric.triggers_revenue_real).to eq(0)

      expect(shop_metric.digests_sent).to eq(4)
      expect(shop_metric.digests_clicked).to eq(3)
      expect(shop_metric.digests_orders).to eq(1)
      expect(shop_metric.digests_revenue).to eq(200)
      expect(shop_metric.digests_orders_real).to eq(1)
      expect(shop_metric.digests_revenue_real).to eq(200)

      expect(shop_metric.subscription_popup_showed).to eq(1)
      expect(shop_metric.subscription_accepted).to eq(1)

      expect(shop_metric.product_views_total).to eq(3)
      expect(shop_metric.product_views_recommended).to eq(1)

    end



  end
end
