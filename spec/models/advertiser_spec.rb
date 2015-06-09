require 'rails_helper'

RSpec.describe Advertiser, :type => :model do

  context 'balance' do

    it 'has valid factory' do
      expect(create(:advertiser)).to be_valid
    end

    it 'allows positive and negative balance' do
      advertiser = create(:advertiser)
      expect(advertiser.balance).to eq(0)
      advertiser.change_balance(30)
      expect(advertiser.balance).to eq(30)
      advertiser.change_balance(-60)
      expect(advertiser.balance).to eq(-30)
    end

  end

  let!(:shop) { create(:shop) }
  let!(:promotion) { create(:advertiser) }

  it 'has a valid factory' do
    expect(promotion).to be_valid
  end



end
