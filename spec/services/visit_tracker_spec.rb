require 'rails_helper'

describe VisitTracker do

  let!(:user) { create(:user) }
  let!(:customer) { create(:customer) }
  let!(:shop) { create(:shop, customer: customer) }

  subject { VisitTracker.new(shop) }

  describe '.track' do


    it 'changes visits' do
      expect{ subject.track(user) }.to change(Visit, :count).from(0).to(1)
      expect{ subject.track(user) }.to_not change(Visit, :count)
      expect(Visit.first.pages).to eq(2)
    end

  end

  describe '.track with time zone' do
    before { allow(Time).to receive(:now).and_return(Time.parse('2016-10-05 05:00:00 UTC +00:00')) }
    let!(:customer) { create(:customer, time_zone: 'Pacific Time (US & Canada)') }

    it 'created date yesterday for UTC' do
      subject.track(user)
      expect(Visit.first.date.to_s).to eq('2016-10-04')
    end
  end

end
