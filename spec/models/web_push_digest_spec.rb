require 'rails_helper'

RSpec.describe WebPushDigest, :type => :model do

  let!(:shop) { create(:shop) }
  let!(:web_push_digest) { create(:web_push_digest, shop: shop, subject: 'Hello') }

  it 'has a valid factory' do
    expect(web_push_digest).to be_valid
  end

end
