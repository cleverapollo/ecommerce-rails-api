require 'rails_helper'

RSpec.describe Advertiser, :type => :model do

  context 'balance' do

    it 'has valid factory' do
      expect(create(:advertiser)).to be_valid
    end

  end

  let!(:shop) { create(:shop) }
  let!(:promotion) { create(:advertiser) }

  it 'has a valid factory' do
    expect(promotion).to be_valid
  end



end
