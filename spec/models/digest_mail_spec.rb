require 'rails_helper'

describe DigestMail do
  let!(:shop) { create(:shop, customer: customer) }
  let!(:user) { create(:user) }
  let!(:client) { create(:client, :with_email, shop: shop, user: user) }
  let!(:shop_email) { create(:shop_email, shop: shop, email: client.email) }
  let!(:mailing) { create(:digest_mailing, shop: shop) }
  let!(:batch) { create(:digest_mailing_batch, mailing: mailing, shop: shop) }

  context 'Default' do
    let!(:customer) { create(:customer) }
    let!(:digest_mail) { create(:digest_mail, shop: shop, client: client, mailing: mailing, batch: batch) }

    it 'has a valid factory' do
      expect(digest_mail).to be_valid
    end

    describe '#mark_as_opened!' do
      it 'marks mailing as opened' do
        expect{ digest_mail.mark_as_opened! }.to change{ digest_mail.opened }.from(false).to(true)
      end
    end

    describe '#mark_as_clicked!' do
      it 'marks mailing as clicked' do
        expect{ digest_mail.mark_as_clicked! }.to change{ digest_mail.clicked }.from(false).to(true)
      end
    end

    describe '#tracking_url' do
      it 'returns tracking url' do
        expect(digest_mail.tracking_url).to eq("http://#{Rees46::HOST}/track/digest/#{digest_mail.code}.png?shop_id=#{shop.uniqid}")
      end
    end

    describe '#mark_as_bounced!' do
      subject { digest_mail.mark_as_bounced!(DigestMail::BOUNCE_ABUSE) }

      it 'marks mailing as bounced' do
        expect(digest_mail.bounce_reason).to be_nil
        expect{ subject }.to change{ digest_mail.bounced }.from(false).to(true)
        expect(digest_mail.bounce_reason).to eq DigestMail::BOUNCE_ABUSE
      end

      it 'purges client email' do
        expect{ subject }.to change{ client.reload.email }.to(nil)
      end

      it 'insert invalid email' do
        subject
        expect(InvalidEmail.count).to eq(1)
      end
    end
  end

  context 'Time zone' do
    before { allow(Time).to receive(:now).and_return(Time.parse('2016-10-05 05:00:00 UTC +00:00')) }

    describe 'default' do
      let!(:customer) { create(:customer) }
      let!(:digest_mail) { create(:digest_mail, shop: shop, client: client, mailing: mailing, batch: batch) }

      it 'created date at today correctly' do
        expect(digest_mail.date.to_s).to eq('2016-10-05')
      end
    end

    describe 'PST' do
      let!(:customer) { create(:customer, time_zone: 'Pacific Time (US & Canada)') }
      let!(:digest_mail) { create(:digest_mail, shop: shop, client: client, mailing: mailing, batch: batch) }

      it 'created date yesterday for UTC' do
        expect(digest_mail.date.to_s).to eq('2016-10-04')
      end
    end

    describe 'Vladivostok' do
      before { allow(Time).to receive(:now).and_return(Time.parse('2016-10-05 15:00:00 UTC +00:00')) }
      let!(:customer) { create(:customer, time_zone: 'Vladivostok') }
      let!(:digest_mail) { create(:digest_mail, shop: shop, client: client, mailing: mailing, batch: batch) }

      it 'created date tomorrow for UTC' do
        expect(digest_mail.date.to_s).to eq('2016-10-06')
      end
    end
  end
end
