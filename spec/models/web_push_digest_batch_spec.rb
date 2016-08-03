require 'rails_helper'

RSpec.describe WebPushDigestBatch, :type => :model do

  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:client) { create(:client, :with_email, shop: shop, user: user) }
  let!(:web_push_digest) { create(:web_push_digest, shop: shop, subject: 'Hello', message: 'Sale out', url: 'http://...') }
  let!(:web_push_digest_batch) { create(:web_push_digest_batch, shop: shop, mailing: web_push_digest, start_id: client.id, end_id: client.id + 1) }

  it 'has a valid factory' do
    expect(web_push_digest_batch).to be_valid
  end

  describe '#complete!' do
    it 'marks batch as completed' do
      expect{ web_push_digest_batch.complete! }.to change{ web_push_digest_batch.completed }.from(false).to(true)
    end
  end

end
