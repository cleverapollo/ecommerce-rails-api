require 'rails_helper'

describe WebPush::Triggers::Base do


  describe '.methods' do

    let!(:user) { create(:user) }
    let!(:shop) { create(:shop) }
    let!(:client) { create(:client, user: user, shop: shop) }

    it 'has correct initializer' do
      expect(WebPush::Triggers::Base.new(client).client).to eq client
    end

    it 'raise NotImplementedError' do
      expect{WebPush::Triggers::Base.new(client).triggered?}.to raise_error NotImplementedError
    end

  end



end
