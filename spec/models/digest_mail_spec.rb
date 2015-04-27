require 'rails_helper'

describe DigestMail do
  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:client) { create(:client, :with_email, shop: shop, user: user) }
  let!(:mailing) { create(:digest_mailing, shop: shop) }
  let!(:batch) { create(:digest_mailing_batch, mailing: mailing) }
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
      expect(digest_mail.tracking_url).to eq("http://#{Rees46::HOST}/track/digest/test.png")
    end
  end

  describe '#mark_as_bounced!' do
    subject { digest_mail.mark_as_bounced! }

    it 'marks mailing as bounced' do
      expect{ subject }.to change{ digest_mail.bounced }.from(false).to(true)
    end

    it 'purges client email' do
      expect{ subject }.to change{ client.reload.email }.to(nil)
    end
  end
end
