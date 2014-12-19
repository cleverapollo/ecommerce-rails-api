require 'spec_helper'

describe DigestMailingRecommendationsCalculatorWorker do
  let!(:shop) { create(:shop) }
  let!(:audience) { create(:audience, shop: shop) }
  let!(:inactive_audience) { create(:audience, shop: shop, active: false) }

  before do
    10.times {
      u = create(:user)
      i = create(:item, shop: shop)
      a = create(:action, item: i, shop: shop, user: u)
    }
    ActionMailer::Base.deliveries = []
  end

  describe '#perform' do
    subject { DigestMailingRecommendationsCalculatorWorker.new }
    let(:params) { {'shop_id' => shop.uniqid, 'shop_secret' => shop.secret, 'email' => 'test@example.com', 'mode' => 'audiences' } }

    it 'fetches shop by credentials' do
      subject.perform(params)
      expect(subject.shop).to eq(shop)
    end

    it 'fetches shop active audiences' do
      subject.perform(params)
      expect(subject.users).to match_array([{ external_id: audience.external_id, user: audience.user}])
    end

    context 'recommendations count' do
      context 'when passed' do
        before { params['recommendations_count'] = 5 }
        it 'fetches recommendations_count' do
          subject.perform(params)
          expect(subject.recommendations_count).to eq(5)
        end
      end
      context 'when not passed' do
        it 'sets recommendations_count to default' do
          subject.perform(params)
          expect(subject.recommendations_count).to eq(10)
        end
      end
    end

    it 'opens recommendations calculator' do
      allow(DigestMailingRecommendationsCalculator).to receive(:open)
      subject.perform(params)
      expect(DigestMailingRecommendationsCalculator).to have_received(:open)
    end

    it 'iterates through users and gets recommendations' do
      subject.perform(params)
      expect(subject.recommendations.first[0]).to eq(audience.external_id)
      expect(subject.recommendations.first[1]).to eq(Item.pluck(:uniqid).join(';'))
    end

    it 'formats recommendations as CSV' do
      subject.perform(params)
      expect(subject.csv).to be_present
    end

    it 'sends an email with recommendations to given e-mail address' do
      subject.perform(params)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end
  end
end
