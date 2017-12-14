require 'rails_helper'

RSpec.describe ShopEmail, :type => :model do
  let!(:shop) { create(:shop) }

  context 'validates' do
    it 'valid' do
      expect(shop.shop_emails.new(email: 'test@email.com').valid?).to be_truthy
    end

    it 'invalid' do
      expect(shop.shop_emails.new.valid?).to be_falsey
    end
  end
end
