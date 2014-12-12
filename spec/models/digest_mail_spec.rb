require 'spec_helper'

describe DigestMail do
  let!(:shop) { create(:shop) }
  let!(:mailing) { create(:digest_mailing, shop: shop) }
  let!(:batch) { create(:digest_mailing_batch, mailing: mailing) }
  let!(:audience) { create(:audience, shop: shop) }
  subject { create(:digest_mail, shop: shop, audience: audience, mailing: mailing, batch: batch).reload }

  describe '#tracking_url' do
    it 'returns URL of tracking pixel' do
      expect(subject.tracking_url).to eq("http://127.0.0.1:8080/track/digest/#{subject.code}.png")
    end
  end
end
