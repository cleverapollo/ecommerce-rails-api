require 'rails_helper'

describe WebPush::Statistics do
  before {
    allow(Time).to receive(:now).and_return(Time.parse('2016-06-16 12:00:00 UTC +00:00'))
    allow(Date).to receive(:current).and_return(Time.now.to_date)
  }

  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:web_push_trigger) { create(:web_push_trigger, shop: shop, trigger_type: 'recently_purchased', enabled: true) }
  let!(:client) { create(:client, shop: shop) }

  # Today
  let!(:web_push_trigger_message_1) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: true, clicked: true, created_at: 1.hour.ago) }
  let!(:web_push_trigger_message_2) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: true, clicked: false, created_at: 2.hour.ago) }
  let!(:web_push_trigger_message_3) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: false, clicked: false, created_at: 3.hour.ago) }
  let!(:order_1) { create(:order, shop: shop, user: client.user, source_id: web_push_trigger_message_1.id, source_type: 'WebPushTriggerMessage', value: 100, date: 1.hour.ago) }

  # Yesterday
  let!(:web_push_trigger_message_4) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: true, clicked: true, created_at: 25.hour.ago, date: 25.hour.ago) }
  let!(:web_push_trigger_message_5) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: true, clicked: true, created_at: 25.hour.ago, date: 25.hour.ago) }
  let!(:web_push_trigger_message_6) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: true, clicked: false, created_at: 26.hour.ago, date: 26.hour.ago) }
  let!(:web_push_trigger_message_7) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: false, clicked: false, created_at: 27.hour.ago, date: 27.hour.ago) }
  let!(:order_2) { create(:order, shop: shop, user: client.user, source_id: web_push_trigger_message_4.id, source_type: 'WebPushTriggerMessage', value: 200, date: 25.hour.ago) }

  # This month
  let!(:web_push_trigger_message_8) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: false, clicked: false, created_at: 3.day.ago, date: 3.day.ago) }

  # Prev month
  let!(:web_push_trigger_message_9) { create(:web_push_trigger_message, shop: shop, client: client, web_push_trigger: web_push_trigger, showed: false, clicked: false, created_at: 33.day.ago, date: 33.day.ago) }

  subject { WebPush::Statistics.new(shop).recalculate; WebPush::Statistics.new(shop).recalculate_prev_month }

  it 'works' do
    subject
    web_push_trigger.reload
    expect(web_push_trigger.statistic[:today][:sent]).to eq(3)
    expect(web_push_trigger.statistic[:today][:showed]).to eq(2)
    expect(web_push_trigger.statistic[:today][:clicked]).to eq(1)
    expect(web_push_trigger.statistic[:today][:purchases]).to eq(1)

    expect(web_push_trigger.statistic[:yesterday][:sent]).to eq(4)
    expect(web_push_trigger.statistic[:yesterday][:showed]).to eq(3)
    expect(web_push_trigger.statistic[:yesterday][:clicked]).to eq(2)
    expect(web_push_trigger.statistic[:yesterday][:purchases]).to eq(1)

    expect(web_push_trigger.statistic[:this_month][:sent]).to eq(8)
    expect(web_push_trigger.statistic[:this_month][:showed]).to eq(5)
    expect(web_push_trigger.statistic[:this_month][:clicked]).to eq(3)
    expect(web_push_trigger.statistic[:this_month][:purchases]).to eq(2)
    expect(web_push_trigger.statistic[:this_month][:purchases_value]).to eq(300)

    expect(web_push_trigger.statistic[:previous_month][:sent]).to eq(1)
    expect(web_push_trigger.statistic[:previous_month][:showed]).to eq(0)
    expect(web_push_trigger.statistic[:previous_month][:clicked]).to eq(0)
    expect(web_push_trigger.statistic[:previous_month][:purchases]).to eq(0)
    expect(web_push_trigger.statistic[:previous_month][:purchases_value]).to eq(0)

    expect(web_push_trigger.statistic[:all][:sent]).to eq(9)
    expect(web_push_trigger.statistic[:all][:showed]).to eq(5)
    expect(web_push_trigger.statistic[:all][:clicked]).to eq(3)
    expect(web_push_trigger.statistic[:all][:purchases]).to eq(2)
    expect(web_push_trigger.statistic[:all][:purchases_value]).to eq(300)
  end
end
