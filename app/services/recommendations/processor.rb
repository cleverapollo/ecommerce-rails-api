module Recommendations
  class Processor
    class << self
      def process(params)
        recommender_implementation = Recommenders::BaseRecommender.get_implementation_for(params.type)
        recommender_implementation.recommendations(params)
      end
    end
  end
end
