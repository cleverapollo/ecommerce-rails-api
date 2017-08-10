require 'rails_helper'

describe SearchEngine::Processor do
  describe '.process' do
    before do
      @shop = create(:shop)
      @params = OpenStruct.new(type: 'instant_search',
                                shop: @shop,
                                search_query: 'lua',
                                user: create(:user),
                                limit: 10
      )
      @recommendations = [1, 2, 3]

      allow(SearchEngine::Base).to receive(:get_implementation_for) {
        SearchEngine::InstantSearch
      }
      allow_any_instance_of(SearchEngine::InstantSearch).to receive(:recommendations) {
        @recommendations
      }
    end
    subject { SearchEngine::Processor.process(@params) }

    it 'fetches recommender implementation' do
      subject

      expect(SearchEngine::Base).to have_received(:get_implementation_for).with(@params.type)
    end

    it 'calls recommendations on it' do
      expect(subject).to match_array(@recommendations)
    end
  end
end
