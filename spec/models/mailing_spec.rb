require 'spec_helper'

describe Mailing do
  describe '#total_statistics' do
    let(:mailing) { create(:mailing) }

    it 'gathers total statistics' do
      stats = {
        total: 5,
        with_recommendations: 4,
        no_recommendations: 1,
        failed: 0,
        duration: 5.0,
      }

      create(:mailing_batch, mailing: mailing, statistics: stats)

      expect(mailing.total_statistics).to eq(stats)
    end
  end
end
