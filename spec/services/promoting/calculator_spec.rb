require 'rails_helper'

describe Promoting::Calculator do
  describe '.previous_days' do

    let!(:advertiser) { create(:advertiser, balance: 1000, cpm: 1500) }
    let!(:advertiser_statistic) {create(:advertiser_statistic, advertiser: advertiser, date: Date.yesterday, views: 1000)}

    it 'calculates cost and decrease balance of advertiser' do
      Promoting::Calculator.previous_days
      advertiser_statistic.reload
      advertiser.reload
      expect(advertiser_statistic.cost).to eq(1500)
      expect(advertiser.balance).to eq(-500)
    end



  end
end
