require 'rails_helper'

describe TriggerMailings::Statistics do
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:trigger_mailing) { create(:trigger_mailing, shop: shop, trigger_type: 'recently_purchased', enabled: true) }
  let!(:client) { create(:client, shop: shop) }

  # Today
  let!(:trigger_mail_1) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: true, created_at: 1.hour.ago) }
  let!(:trigger_mail_2) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: false, created_at: 2.hour.ago) }
  let!(:trigger_mail_3) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: false, clicked: false, created_at: 3.hour.ago) }
  let!(:order_1) { create(:order, shop: shop, user: client.user, source_id: trigger_mail_1.id, source_type: 'TriggerMail') }

  # Yesterday
  let!(:trigger_mail_4) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: true, created_at: 25.hour.ago) }
  let!(:trigger_mail_5) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: true, created_at: 25.hour.ago) }
  let!(:trigger_mail_6) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: true, clicked: false, created_at: 26.hour.ago) }
  let!(:trigger_mail_7) { create(:trigger_mail, shop: shop, client: client, mailing: trigger_mailing, opened: false, clicked: false, created_at: 27.hour.ago) }
  let!(:order_2) { create(:order, shop: shop, user: client.user, source_id: trigger_mail_4.id, source_type: 'TriggerMail') }

  subject { TriggerMailings::Statistics.new(shop).recalculate }

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
  end
end
