require 'rails_helper'

describe ShopKPI do

  let!(:user) { create(:user) }
  let!(:user_2) { create(:user) }
  let!(:user_3) { create(:user) }
  let!(:session) { create(:session, user: user, code: '1') }
  let!(:session2) { create(:session, user: user_2, code: '2') }
  let!(:session3) { create(:session, user: user_3, code: '3') }


  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }

  let!(:client) {create(:client, user: user, shop: shop, subscription_popup_showed: true, accepted_subscription: true, web_push_subscription_popup_showed: true, web_push_subscription_permission_showed: true, web_push_enabled: true )}

  let!(:item_1) { create(:item, shop: shop, price: 100, is_available: 1) }
  let!(:item_2) { create(:item, shop: shop, price: 200, is_fashion: 1, widgetable: true, is_available: 1) }
  let!(:item_3) { create(:item, shop: shop, price: 200, is_auto: 1, widgetable: true, is_available: 1) }

  let!(:action_1) { create(:action_cl, shop: shop, object_type: 'Item', object_id: item_1.uniqid, session: user.sessions.first, event: 'cart', date: Date.yesterday) }
  let!(:action_2) { create(:action_cl, shop: shop, object_type: 'Item', object_id: item_2.uniqid, session: user.sessions.first, event: 'view', date: Date.yesterday, recommended_by: 'digest_mail') }
  let!(:action_3) { create(:action_cl, shop: shop, object_type: 'Item', object_id: item_2.uniqid, session: user_2.sessions.first, event: 'cart', date: Date.yesterday) }
  let!(:action_4) { create(:action_cl, shop: shop, object_type: 'Item', object_id: item_2.uniqid, session: user_3.sessions.first,  event: 'view', date: Date.yesterday) }
  let!(:action_5) { create(:action_cl, shop: shop, object_type: 'Item', object_id: item_1.uniqid, session: user_3.sessions.first,  event: 'view', date: Date.current) }

  let!(:client_cart_1) { create(:client_cart, shop: shop, items: [item_1.id, item_2.id], user: user_3, date: Date.yesterday) }
  let!(:client_cart_2) { create(:client_cart, shop: shop, items: [item_1.id], user: user, date: Date.today) }

  let!(:trigger_mailing_1) { create(:trigger_mailing, trigger_type: 'type_1', shop: shop, enabled: true) }
  let!(:trigger_mailing_2) { create(:trigger_mailing, trigger_type: 'type_2', shop: shop, enabled: true) }
  let!(:trigger_mailing_3) { create(:trigger_mailing, trigger_type: 'type_3', shop: shop, enabled: false) }
  let!(:trigger_mail_1) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_1, client: client, created_at: (Date.yesterday + 2.hours), clicked: true) }
  let!(:trigger_mail_2) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_1, client: client, created_at: (Date.yesterday + 2.hours)) }
  let!(:trigger_mail_3) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_2, client: client, created_at: (Date.yesterday + 2.hours)) }
  let!(:trigger_mail_4) { create(:trigger_mail, shop: shop, mailing: trigger_mailing_2, client: client, created_at: (Date.yesterday + 2.hours)) }

  let!(:web_push_trigger_1) { create(:web_push_trigger, trigger_type: 'type_1', shop: shop, subject: 'Subject', message: 'message', enabled: true) }
  let!(:web_push_trigger_2) { create(:web_push_trigger, trigger_type: 'type_2', shop: shop, subject: 'Subject', message: 'message', enabled: true) }
  let!(:web_push_trigger_3) { create(:web_push_trigger, trigger_type: 'type_3', shop: shop, subject: 'Subject', message: 'message', enabled: false) }
  let!(:web_push_trigger_message_1) { create(:web_push_trigger_message, shop: shop, web_push_trigger: web_push_trigger_1, trigger_data: {test: ''}, client: client, created_at: (Date.yesterday + 2.hours), clicked: true) }
  let!(:web_push_trigger_message_2) { create(:web_push_trigger_message, shop: shop, web_push_trigger: web_push_trigger_1, trigger_data: {test: ''}, client: client, created_at: (Date.yesterday + 2.hours)) }
  let!(:web_push_trigger_message_3) { create(:web_push_trigger_message, shop: shop, web_push_trigger: web_push_trigger_2, trigger_data: {test: ''}, client: client, created_at: (Date.yesterday + 2.hours)) }
  let!(:web_push_trigger_message_4) { create(:web_push_trigger_message, shop: shop, web_push_trigger: web_push_trigger_2, trigger_data: {test: ''}, client: client, created_at: (Date.yesterday + 2.hours)) }

  let!(:web_push_digest) { create(:web_push_digest, shop: shop) }
  let!(:web_push_digest_message_1) { create(:web_push_digest_message, shop: shop, web_push_digest: web_push_digest, created_at: (Date.yesterday + 2.hours), clicked: true) }
  let!(:web_push_digest_message_2) { create(:web_push_digest_message, shop: shop, web_push_digest: web_push_digest, created_at: (Date.yesterday + 2.hours)) }

  let!(:digest_mailing) { create(:digest_mailing, shop: shop) }
  let!(:digest_mailing_batch) { create(:digest_mailing_batch, mailing: digest_mailing, shop: shop) }

  let!(:digest_mail_1) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, clicked: true, created_at: (Date.yesterday + 2.hours)) }
  let!(:digest_mail_2) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: (Date.yesterday + 2.hours), clicked: true) }
  let!(:digest_mail_3) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: (Date.yesterday + 2.hours)) }
  let!(:digest_mail_4) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: digest_mailing_batch, created_at: (Date.yesterday + 2.hours), clicked: true) }

  let!(:order_1) { create(:order, user: user, uniqid: '1', shop: shop, value: 100, date: (Date.yesterday + 2.hours), source_id: trigger_mail_1.id, source_type: 'TriggerMail', recommended: true, common_value: 17, recommended_value: 24) }
  let!(:order_2) { create(:order, user: user, uniqid: '2', shop: shop, status: 1, value: 200, date: (Date.yesterday + 2.hours), source_id: digest_mail_1.id, source_type: 'DigestMail', recommended: false, common_value: 133, recommended_value: 13) }
  let!(:order_3) { create(:order, user: user, uniqid: '3', shop: shop, value: 100, date: (Date.yesterday + 2.hours), source_id: web_push_trigger_message_1.id, source_type: 'WebPushTriggerMessage', recommended: true, common_value: 17, recommended_value: 24) }
  let!(:order_4) { create(:order, user: user, uniqid: '4', shop: shop, value: 100, date: (Date.yesterday + 2.hours), source_id: web_push_digest_message_1.id, source_type: 'WebPushDigestMessage', recommended: true, common_value: 17, recommended_value: 24) }
  let!(:order_item_1) { create(:order_item, order: order_1, item: item_1, shop: shop, recommended_by: 'trigger_mail') }
  let!(:order_item_2) { create(:order_item, order: order_2, item: item_1, shop: shop, recommended_by: 'digest_mail') }
  let!(:order_item_3) { create(:order_item, order: order_3, item: item_1, shop: shop, recommended_by: 'web_push_trigger') }
  let!(:order_item_4) { create(:order_item, order: order_4, item: item_1, shop: shop, recommended_by: 'web_push_digest') }

  let!(:interaction_1) { create(:interaction, item: item_1, shop: shop, user: user, code: 1, recommender_code: 2, created_at: (Date.yesterday + 2.hours)) }
  let!(:interaction_2) { create(:interaction, item: item_2, shop: shop, user: user, code: 1, created_at: (Date.yesterday + 2.hours)) }
  let!(:interaction_3) { create(:interaction, item: item_2, shop: shop, user: user, created_at: (Date.yesterday + 2.hours)) }
  let!(:interaction_4) { create(:interaction, item: item_1, shop: shop, user: user, code: 1, recommender_code: 2, created_at: 7.days.ago) }

  let!(:visit_1) { create(:visit_cl, shop: shop, user: user, session: user.sessions.first, date:  Date.yesterday) }
  let!(:visit_2) { create(:visit_cl, shop: shop, user: user_2, session: user_2.sessions.first, date:  Date.yesterday) }
  let!(:visit_3) { create(:visit_cl, shop: shop, user: user_3, session: user_3.sessions.first, date:  Date.yesterday) }

  let!(:params) { { shop_id: shop.uniqid, ssid: session.code, recommender_type: 'interesting' } }

  describe '.calculate' do

    subject { ShopKPI.new(shop, Date.yesterday).calculate_statistics }

    it 'finds or initialize only one object per date' do
      expect{subject}.to change(ShopMetric, :count).from(0).to(1)
      subject
      expect(ShopMetric.count).to eq(1)
    end

    it 'calculates correct without tracking orders status' do
      subject
      shop_metric = ShopMetric.first
      expect(shop_metric.orders).to eq(4)
      expect(shop_metric.real_orders).to eq(1)
      expect(shop_metric.revenue).to eq(500)
      expect(shop_metric.real_revenue).to eq(200)
      expect(shop_metric.visitors).to eq(3)
      expect(shop_metric.products_viewed).to eq(2)

      expect(shop_metric.orders_original_count).to eq(1)
      expect(shop_metric.orders_recommended_count).to eq(3)
      expect(shop_metric.orders_original_revenue).to eq(184)
      expect(shop_metric.orders_recommended_revenue).to eq(85)

      expect(shop_metric.abandoned_products).to eq(2)
      expect(shop_metric.abandoned_money).to eq(300)


      expect(shop_metric.triggers_enabled_count).to eq(2)
      expect(shop_metric.triggers_sent).to eq(4)
      expect(shop_metric.triggers_clicked).to eq(1)
      expect(shop_metric.triggers_orders).to eq(1)
      expect(shop_metric.triggers_revenue).to eq(100)
      expect(shop_metric.triggers_orders_real).to eq(0)
      expect(shop_metric.triggers_revenue_real).to eq(0)

      expect(shop_metric.web_push_triggers_sent).to eq(4)
      expect(shop_metric.web_push_triggers_clicked).to eq(1)
      expect(shop_metric.web_push_triggers_orders).to eq(1)
      expect(shop_metric.web_push_triggers_revenue).to eq(100)
      expect(shop_metric.web_push_triggers_orders_real).to eq(0)
      expect(shop_metric.web_push_triggers_revenue_real).to eq(0)

      expect(shop_metric.web_push_digests_sent).to eq(2)
      expect(shop_metric.web_push_digests_clicked).to eq(1)
      expect(shop_metric.web_push_digests_orders).to eq(1)
      expect(shop_metric.web_push_digests_revenue).to eq(100)
      expect(shop_metric.web_push_digests_orders_real).to eq(0)
      expect(shop_metric.web_push_digests_revenue_real).to eq(0)

      expect(shop_metric.digests_sent).to eq(4)
      expect(shop_metric.digests_clicked).to eq(3)
      expect(shop_metric.digests_orders).to eq(1)
      expect(shop_metric.digests_revenue).to eq(200)
      expect(shop_metric.digests_orders_real).to eq(1)
      expect(shop_metric.digests_revenue_real).to eq(200)

      expect(shop_metric.subscription_popup_showed).to eq(1)
      expect(shop_metric.subscription_accepted).to eq(1)

      expect(shop_metric.web_push_subscription_popup_showed).to eq(1)
      expect(shop_metric.web_push_subscription_permission_showed).to eq(1)
      expect(shop_metric.web_push_subscription_accepted).to eq(1)

      expect(shop_metric.product_views_total).to eq(3)
      expect(shop_metric.product_views_recommended).to eq(1)
    end

    it 'calculates products' do
      ShopKPI.new(shop, Date.yesterday).calculate_products
      shop_metric = ShopMetric.first
      expect(shop_metric.top_products).to eq([{id: item_1.id, name: item_1.name, url: item_1.url, amount: 4}.stringify_keys])
      expect(shop_metric.products_statistics).to eq({ total: 3, recommendable: 3, widgetable: 2, ignored: 0,  industrial: 2}.stringify_keys)
    end

    # Была проблема в том, что каждый раз, когда делали перерасчет за предыдущие дни исходная сумма не обнулялась,
    # а просто суммировалась со значением, рассчитанным в прошлый раз. Поэтому были безумные суммы.
    it 'does not break abandoned carts statistics with summarizing money and nullifying count' do
      expect{subject}.to change(ShopMetric, :count).from(0).to(1)
      ShopKPI.new(shop, Date.yesterday).calculate_statistics
      ShopKPI.new(shop, Date.today).calculate_statistics
      expect(ShopMetric.count).to eq(2)
      expect(ShopMetric.order(:id).first.abandoned_products).to eq(2)
      expect(ShopMetric.order(:id).first.abandoned_money).to eq(300)
      expect(ShopMetric.order(:id).last.abandoned_products).to eq(1)
      expect(ShopMetric.order(:id).last.abandoned_money).to eq(100)

    end



  end

  describe '.calculate today', type: :request do

    let!(:mailings_settings) { create(:mailings_settings, shop: shop, mailing_service: MailingsSettings::MAILING_SERVICE_MAILGANER) }
    let!(:subscription_plan) { create(:subscription_plan, shop: shop, paid_till: 1.month.from_now, product: 'product.recommendations', price: 100) }

    subject { ShopKPI.new(shop, Date.current).calculate_statistics }

    it 'finds or initialize only one object per date' do
      expect{subject}.to change(ShopMetric, :count).from(0).to(1)
      subject
      expect(ShopMetric.count).to eq(1)
    end

    it 'calculates correct today' do
      get '/recommend', params

      expect(response.code).to eq '200'

      subject
      shop_metric = ShopMetric.first

      expect(shop_metric.subscription_popup_showed).to eq(1)
      expect(shop_metric.subscription_accepted).to eq(1)

      expect(shop_metric.web_push_subscription_popup_showed).to eq(1)
      expect(shop_metric.web_push_subscription_permission_showed).to eq(1)
      expect(shop_metric.web_push_subscription_accepted).to eq(1)

      expect(shop_metric.recommendation_requests).to eq(1)

      Redis.current.del("recommender.request.#{shop.id}.#{Time.now.utc.to_date}")
    end
  end



end
