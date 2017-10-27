require 'rails_helper'

describe OrdersImportWorker do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:session) { create(:session, user: user) }
  let!(:order) { create(:order, shop: shop, user: user, date: Date.current) }

  let!(:item_1) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
  let!(:item_2) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }
  let!(:item_3) { create(:item, shop: shop, is_available: true, ignored: false, widgetable: true, is_cosmetic: true, cosmetic_periodic: false) }

  let!(:order_item_1) { create(:order_item, order: order, item: item_1, amount: 1, shop: shop) }
  let!(:order_item_2) { create(:order_item, order: order, item: item_2, amount: 2, shop: shop) }
  let!(:order_item_3) { create(:order_item, order: order, item: item_3, amount: 1, shop: shop, recommended_by: 'popular') }

  context 'source' do
    let!(:client) { create(:client, :with_email, shop: shop, user: user) }
    let!(:mailing) { create(:digest_mailing, shop: shop) }
    let!(:batch) { create(:digest_mailing_batch, mailing: mailing, shop: shop) }
    let!(:digest_mail) { create(:digest_mail, shop: shop, client: client, mailing: mailing, batch: batch) }

    it 'recommended by with source params' do
      OrderPersistWorker.new.perform(order.id, { session: session.code, current_session_code: 'test', order_price: 450, source: {'from' => 'digest_mail', 'code' => digest_mail.code } })
      order.reload
      expect(order.recommended).to be_truthy
      expect(order.value).to eq(450)
      expect(order.recommended_value).to eq(400)
      expect(order.common_value).to eq(0)
      expect(order.source_id).to eq(digest_mail.id)
      expect(order.source_type).to eq('DigestMail')

      expect(order_item_1.reload.recommended_by).to eq('digest_mail')
      expect(order_item_2.reload.recommended_by).to eq('digest_mail')
      expect(order_item_3.reload.recommended_by).to eq('digest_mail')
    end

    it 'recommended by without source params' do
      allow(ClickhouseQueue).to receive(:order_items).exactly(3).times
      ActionCl.create!(shop: shop, session: session, current_session_code: 'test', event: 'view', object_type: 'Item', object_id: item_1.uniqid, recommended_by: 'digest_mail', recommended_code: digest_mail.code, date: 1.day.ago.to_date, useragent: 'test')
      OrderPersistWorker.new.perform(order.id, { session: session.code, current_session_code: 'test', order_price: 450 })
      order.reload
      expect(order.recommended).to be_truthy
      expect(order.value).to eq(450)
      expect(order.recommended_value).to eq(400)
      expect(order.common_value).to eq(0)
      expect(order.source_id).to eq(digest_mail.id)
      expect(order.source_type).to eq('DigestMail')

      expect(order_item_1.reload.recommended_by).to eq('digest_mail')
      expect(order_item_2.reload.recommended_by).to eq('digest_mail')
      expect(order_item_3.reload.recommended_by).to eq('digest_mail')
    end

    it 'recommended by without params' do
      allow(ClickhouseQueue).to receive(:order_items).exactly(0).times
      ActionCl.create!(shop: shop, session: session, current_session_code: 'test', event: 'view', object_type: 'Item', object_id: item_1.uniqid, recommended_by: 'digest_mail', recommended_code: digest_mail.code, date: 1.day.ago.to_date, useragent: 'test')
      OrderPersistWorker.new.perform(order.id)
      order.reload
      expect(order.recommended).to be_truthy
      expect(order.source_id).to eq(digest_mail.id)
      expect(order.source_type).to eq('DigestMail')
      expect(order_item_1.reload.recommended_by).to eq('digest_mail')
      expect(order_item_2.reload.recommended_by).to eq('digest_mail')
      expect(order_item_3.reload.recommended_by).to eq('digest_mail')
    end
  end

  context 'recommender' do
    let!(:action) { create(:action_cl, shop: shop, session: session, event: 'view', object_type: 'Item', object_id: item_1.uniqid, recommended_by: 'similar', date: 1.day.ago.to_date) }

    it 'change item recommended_by' do
      OrderPersistWorker.new.perform(order.id, { session: session.code, current_session_code: 'test' })
      order.reload
      expect(order.recommended).to be_truthy
      expect(order.value).to eq(400)
      expect(order.recommended_value).to eq(200)
      expect(order.common_value).to eq(200)
      expect(order.source_id).to be_nil
      expect(order.source_type).to be_nil

      expect(order_item_1.reload.recommended_by).to eq('similar')
      expect(order_item_2.reload.recommended_by).to be_nil
      expect(order_item_3.reload.recommended_by).to eq('popular')
    end
  end

  context 'search' do
    let!(:action) { create(:action_cl, shop: shop, session: session, event: 'view', object_type: 'Item', object_id: item_1.uniqid, recommended_by: 'instant_search', recommended_code: 'coat', date: 1.day.ago.to_date) }

    it 'change item recommended_by' do
      order_item_2.delete
      order_item_3.delete
      allow(ClickhouseQueue).to receive(:push).with('order_items', {
          session_id: session.id,
          shop_id: shop.id,
          user_id: user.id,
          order_id: order.id,
          item_uniqid: item_1.uniqid,
          amount: 1,
          price: item_1.price,
          recommended_by: 'instant_search',
          recommended_code: 'coat',
          brand: nil
      }, {
          current_session_code: 'test'
      })

      OrderPersistWorker.new.perform(order.id, { session: session.code, current_session_code: 'test' })

      order.reload
      expect(order.recommended).to be_truthy
      expect(order_item_1.reload.recommended_by).to eq('instant_search')
    end
  end
end
