require 'rails_helper'

describe Recommendations::Processor do
  describe '.process' do
    before do
      @shop = create(:shop)
      @params = OpenStruct.new(type: 'interesting',
                                shop: @shop,
                                user: create(:user)
      )
      @recommendations = [1, 2, 3]

      allow(Recommender::Base).to receive(:get_implementation_for) {
        Recommender::Impl::Interesting
      }
      allow_any_instance_of(Recommender::Impl::Interesting).to receive(:recommendations) {
        @recommendations
      }
    end
    subject { Recommendations::Processor.process(@params) }

    it 'fetches recommender implementation' do
      subject

      expect(Recommender::Base).to have_received(:get_implementation_for).with(@params.type)
    end

    it 'calls recommendations on it' do
      expect(subject).to match_array(@recommendations)
    end
  end
end
