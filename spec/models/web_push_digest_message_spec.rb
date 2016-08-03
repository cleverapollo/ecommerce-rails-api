require 'rails_helper'

RSpec.describe WebPushDigestMessage, :type => :model do

  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:client) { create(:client, :with_email, shop: shop, user: user) }
  let!(:web_push_digest) { create(:web_push_digest, shop: shop, subject: 'Hello', message: 'Sale out', url: 'http://...') }
  let!(:web_push_digest_batch) { create(:web_push_digest_batch, shop: shop, mailing: web_push_digest, start_id: client.id, end_id: client.id + 1) }
  let!(:web_push_digest_message) { create(:web_push_digest_message, shop: shop, client: client, web_push_digest: web_push_digest, web_push_digest_batch: web_push_digest_batch) }

  it 'has a valid factory' do
    expect(web_push_digest_message).to be_valid
  end

  describe '#mark_as_clicked!' do
    it 'marks message as clicked' do
      expect{ web_push_digest_message.mark_as_clicked! }.to change{ web_push_digest_message.clicked }.from(false).to(true)
    end
  end

  describe '#mark_as_unsubscribed!' do
    subject { web_push_digest_message.mark_as_unsubscribed! }

    it 'marks mailing as unsubscribed' do
      expect{ subject }.to change{ web_push_digest_message.unsubscribed }.from(false).to(true)
    end

  end

end
