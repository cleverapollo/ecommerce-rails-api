require 'spec_helper'

describe Recommendations::Processor do
  describe '.process' do
    before do
      @params = OpenStruct.new \
                                type: 'interesting'
      @recommendations = [1, 2, 3]

      allow(Recommenders::Base).to receive(:get_implementation_for) {
        Recommenders::Interesting
      }
      allow_any_instance_of(Recommenders::Interesting).to receive(:recommendations) {
        @recommendations
      }
    end
    subject { Recommendations::Processor.process(@params) }

    it 'fetches recommender implementation' do
      subject

      expect(Recommenders::Base).to have_received(:get_implementation_for).with(@params.type)
    end

    it 'calls recommendations on it' do
      expect(subject).to match_array(@recommendations)
    end
  end
end