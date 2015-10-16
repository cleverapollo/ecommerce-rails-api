require 'rails_helper'

RSpec.describe BrandCampaign, :type => :model do

  context 'balance' do

    it 'has valid factory' do
      expect(create(:brand_campaign)).to be_valid
    end

  end

  let!(:shop) { create(:shop) }
  let!(:brand_campaign) { create(:brand_campaign) }

  it 'has a valid factory' do
    expect(brand_campaign).to be_valid
    expect(brand_campaign.downcase_brand).to eq(brand_campaign.brand.downcase)
  end



end
