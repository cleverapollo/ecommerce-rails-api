require 'rails_helper'

describe UserMerger do

  let!(:user) { create(:user) }
  let!(:user_2) { create(:user) }
  let!(:user_3) { create(:user) }


  let!(:shop) { create(:shop) }

  let!(:client) {create(:client, user: user, shop: shop)}

  let!(:item_1) { create(:item, shop: shop, price: 100) }
  let!(:item_2) { create(:item, shop: shop, price: 200) }

  let!(:action_1) { create(:action, shop: shop, item: item_1, user: user, rating: 4.2, timestamp: 20.hours.ago.to_i) }
  let!(:action_2) { create(:action, shop: shop, item: item_2, user: user, timestamp: 20.hours.ago.to_i, recommended_by: 'digest_mail') }
  let!(:action_3) { create(:action, shop: shop, item: item_2, user: user_2, rating: 4.2, timestamp: 20.hours.ago.to_i) }
  let!(:action_4) { create(:action, shop: shop, item: item_2, user: user_3, rating: 3.2, timestamp: 20.hours.ago.to_i) }
  let!(:action_5) { create(:action, shop: shop, item: item_1, user: user_3, rating: 3.2, timestamp: DateTime.current.to_i) }

  let!(:order_1) { create(:order, user: user, uniqid: '1', shop: shop, value: 100, date: 20.hours.ago) }
  let!(:order_2) { create(:order, user: user, uniqid: '2', shop: shop, status: 1, value: 200, date: 20.hours.ago) }
  let!(:order_item_1) { create(:order_item, order: order_1, action: action_1, item: item_1, shop: shop, recommended_by: 'trigger_mail') }
  let!(:order_item_2) { create(:order_item, order: order_2, action: action_2, item: item_1, shop: shop, recommended_by: 'digest_mail') }

  let!(:trigger_mailing_1) { create(:trigger_mailing, trigger_type: 'type_1', shop: shop, enabled: true) }
  let!(:trigger_mailing_2) { create(:trigger_mailing, trigger_type: 'type_2', shop: shop, enabled: true) }
  let!(:trigger_mailing_3) { create(:trigger_mailing, trigger_type: 'type_3', shop: shop, enabled: false) }
  let!(:trigger_mail_1) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_1, client: client, created_at: 20.hours.ago, clicked: true) }
  let!(:trigger_mail_2) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_1, client: client, created_at: 20.hours.ago) }
  let!(:trigger_mail_3) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_2, client: client, created_at: 20.hours.ago) }
  let!(:trigger_mail_4) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_2, client: client, created_at: 20.hours.ago) }

  let!(:digest_mailing) { create(:digest_mailing, shop: shop) }
  let!(:digest_mailing_batch) { create(:digest_mailing_batch, mailing: digest_mailing, shop: shop) }

  let!(:digest_mail_1) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, clicked: true, created_at: 20.hours.ago) }
  let!(:digest_mail_2) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: 20.hours.ago) }
  let!(:digest_mail_3) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: 20.hours.ago) }
  let!(:digest_mail_4) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: 20.hours.ago) }

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
      expect(shop_metric.real_orders).to eq(0)
      expect(shop_metric.revenue).to eq(300)
      expect(shop_metric.real_revenue).to eq(0)
      expect(shop_metric.orders_quality).to eq(0)
      expect(shop_metric.visitors).to eq(3)
      expect(shop_metric.products_viewed).to eq(4)
      expect(shop_metric.abandoned_products).to eq(2)
      expect(shop_metric.abandoned_money).to eq(300)
      expect( shop_metric.conversion.round(2) ).to eq(0.67)
      expect(shop_metric.arpu).to eq(100)
      expect(shop_metric.arppu).to eq(150)
      expect(shop_metric.triggers_enabled_count).to eq(2)
      expect(shop_metric.triggers_ctr).to eq(0.25)
      expect(shop_metric.triggers_orders).to eq(1)
      expect(shop_metric.triggers_revenue).to eq(100)
      expect(shop_metric.digests_ctr).to eq(0.25)
      expect(shop_metric.digests_orders).to eq(1)
      expect(shop_metric.digests_revenue).to eq(200)
    end

    it 'calculates correct with tracking orders status' do
      shop.update track_order_status: true
      subject
      shop_metric = ShopMetric.first
      expect(shop_metric.orders).to eq(2)
      expect(shop_metric.real_orders).to eq(1)
      expect(shop_metric.revenue).to eq(300)
      expect(shop_metric.real_revenue).to eq(200)
      expect(shop_metric.orders_quality).to eq(0.5)
      expect(shop_metric.visitors).to eq(3)
      expect(shop_metric.products_viewed).to eq(4)
      expect(shop_metric.abandoned_products).to eq(2)
      expect(shop_metric.abandoned_money).to eq(300)
      expect( shop_metric.conversion.round(2) ).to eq(0.33)
      expect(shop_metric.arpu.round(2)).to eq(66.67)
      expect(shop_metric.arppu).to eq(200)
      expect(shop_metric.triggers_enabled_count).to eq(2)
      expect(shop_metric.triggers_ctr).to eq(0.25)
      expect(shop_metric.triggers_orders).to eq(0)
      expect(shop_metric.triggers_revenue).to eq(0)
      expect(shop_metric.digests_ctr).to eq(0.25)
      expect(shop_metric.digests_orders).to eq(1)
      expect(shop_metric.digests_revenue).to eq(200)
    end

  end
end
