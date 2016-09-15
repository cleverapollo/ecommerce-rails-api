require 'rails_helper'

describe VisitTracker do

  let!(:user) { create(:user) }
  let!(:shop) { create(:shop) }

  describe '.track' do

    subject { VisitTracker.new(shop) }

    it 'changes visits' do
      expect{ subject.track(user) }.to change(Visit, :count).from(0).to(1)
      expect{ subject.track(user) }.to_not change(Visit, :count)
      expect(Visit.first.pages).to eq(2)
    end

  end

end
