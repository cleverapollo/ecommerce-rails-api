require 'rails_helper'

RSpec.describe WebPushToken, :type => :model do
  describe '.validations' do
    it {
      expect{ WebPushToken.create(client_id: 1, shop_id: 1, token: {endpoint: 'test'}) }.to change(WebPushToken, :count).from(0).to(1)
      expect{ WebPushToken.create(client_id: 1, shop_id: 1, token: {endpoint: 'test'}) }.to_not change(WebPushToken, :count)
    }
  end
end
