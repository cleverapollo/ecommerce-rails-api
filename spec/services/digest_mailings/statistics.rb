require 'rails_helper'

describe DigestMailings::Statistics do
  before {
    allow(Time).to receive(:now).and_return(Time.parse('2016-06-16 12:00:00 UTC +00:00'))
    allow(Date).to receive(:current).and_return(Time.now.to_date)
  }

  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }
  let!(:digest_mailing) { create(:digest_mailing, shop: shop, state: 'finished', finished_at: Time.now) }
  let!(:batch) { create(:digest_mailing_batch, mailing: digest_mailing, shop: shop) }
  let!(:client) { create(:client, shop: shop) }

  # Today
  let!(:digest_mail_1) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: batch, opened: true, clicked: true, created_at: 1.hour.ago) }
  let!(:digest_mail_2) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: batch, opened: true, clicked: false, unsubscribed: true, created_at: 2.hour.ago) }
  let!(:digest_mail_3) { create(:digest_mail, shop: shop, client: client, mailing: digest_mailing, batch: batch, opened: false, clicked: false, bounced: true, created_at: 3.hour.ago) }
  let!(:order_1) { create(:order, shop: shop, user: client.user, source_id: digest_mail_1.id, source_type: 'DigestMail', value: 100, date: 1.hour.ago) }


  subject { DigestMailings::Statistics.recalculate_all; DigestMailings::Statistics.recalculate_today }

  it 'works' do
    subject
    digest_mailing.reload
    expect(digest_mailing.statistic[:sent]).to eq(3)
    expect(digest_mailing.statistic[:opened]).to eq(2)
    expect(digest_mailing.statistic[:clicked]).to eq(1)
    expect(digest_mailing.statistic[:bounced]).to eq(1)
    expect(digest_mailing.statistic[:unsubscribed]).to eq(1)
    expect(digest_mailing.statistic[:purchases]).to eq(1)
  end
end
