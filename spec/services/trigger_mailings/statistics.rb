require 'rails_helper'

describe TriggerMailings::Statistics do
  before {
    allow(Time).to receive(:now).and_return(Time.parse('2016-06-16 12:00:00 UTC +00:00'))
    allow(Date).to receive(:current).and_return(Time.now.to_date)
  }

  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'recently_purchased', enabled: true) }
  let!(:client) { create(:client, shop: shop) }

  # Today
  let!(:trigger_mail_1) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: true, created_at: 1.hour.ago) }
  let!(:trigger_mail_2) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: false, created_at: 2.hour.ago) }
  let!(:trigger_mail_3) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: false, clicked: false, created_at: 3.hour.ago) }
  let!(:order_1) { create(:order, shop: shop, user: client.user, source_id: trigger_mail_1.id, source_type: 'TriggerMail', value: 100, date: 1.hour.ago) }

  # Yesterday
  let!(:trigger_mail_4) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: true, created_at: 25.hour.ago, date: 25.hour.ago) }
  let!(:trigger_mail_5) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: true, created_at: 25.hour.ago, date: 25.hour.ago) }
  let!(:trigger_mail_6) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: false, created_at: 26.hour.ago, date: 26.hour.ago) }
  let!(:trigger_mail_7) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: false, clicked: false, created_at: 27.hour.ago, date: 27.hour.ago) }
  let!(:order_2) { create(:order, shop: shop, user: client.user, source_id: trigger_mail_4.id, source_type: 'TriggerMail', value: 200, date: 25.hour.ago) }

  # This month
  let!(:trigger_mail_8) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: false, clicked: false, created_at: 3.day.ago, date: 3.day.ago) }

  # Prev month
  let!(:trigger_mail_9) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: false, clicked: false, created_at: 33.day.ago, date: 33.day.ago) }

  subject { TriggerMailings::Statistics.new(shop).recalculate; TriggerMailings::Statistics.new(shop).recalculate_prev_month }

  it 'works' do
    subject
    trigger_mailing.reload
    expect(trigger_mailing.statistic[:today][:sent]).to eq(3)
    expect(trigger_mailing.statistic[:today][:opened]).to eq(2)
    expect(trigger_mailing.statistic[:today][:clicked]).to eq(1)
    expect(trigger_mailing.statistic[:today][:purchases]).to eq(1)

    expect(trigger_mailing.statistic[:yesterday][:sent]).to eq(4)
    expect(trigger_mailing.statistic[:yesterday][:opened]).to eq(3)
    expect(trigger_mailing.statistic[:yesterday][:clicked]).to eq(2)
    expect(trigger_mailing.statistic[:yesterday][:purchases]).to eq(1)

    expect(trigger_mailing.statistic[:this_month][:sent]).to eq(8)
    expect(trigger_mailing.statistic[:this_month][:opened]).to eq(5)
    expect(trigger_mailing.statistic[:this_month][:clicked]).to eq(3)
    expect(trigger_mailing.statistic[:this_month][:purchases]).to eq(2)
    expect(trigger_mailing.statistic[:this_month][:purchases_value]).to eq(300)

    expect(trigger_mailing.statistic[:previous_month][:sent]).to eq(1)
    expect(trigger_mailing.statistic[:previous_month][:opened]).to eq(0)
    expect(trigger_mailing.statistic[:previous_month][:clicked]).to eq(0)
    expect(trigger_mailing.statistic[:previous_month][:purchases]).to eq(0)
    expect(trigger_mailing.statistic[:previous_month][:purchases_value]).to eq(0)

    expect(trigger_mailing.statistic[:all][:sent]).to eq(9)
    expect(trigger_mailing.statistic[:all][:opened]).to eq(5)
    expect(trigger_mailing.statistic[:all][:clicked]).to eq(3)
    expect(trigger_mailing.statistic[:all][:purchases]).to eq(2)
    expect(trigger_mailing.statistic[:all][:purchases_value]).to eq(300)
  end
end
