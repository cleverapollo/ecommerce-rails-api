require 'rails_helper'

describe Shop do
  let!(:shop) { create(:shop, connected: true, active: true) }
  let!(:plan) { create(:plan) }

  it 'has valid shop factory' do
      expect(create(:shop)).to be_valid
  end

  describe 'allow_industrial?' do
    before do
      shop.update plan: plan
      shop.update paid_till: (DateTime.now + 1.day)
    end

    context 'plan type: free' do
      it 'not allow industrial' do
        expect(shop.allow_industrial?).to eq(false)
      end
    end

    context 'plan type: coustom' do
      before { plan.update plan_type: 'custom' }

      it 'allow industrial' do
        expect(shop.allow_industrial?).to eq(true)
      end

      it 'not allow industrial' do
        shop.update paid_till: (DateTime.now - 1.day)
        expect(shop.allow_industrial?).to eq(false)
      end
    end
  end
end
