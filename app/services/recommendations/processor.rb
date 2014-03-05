module Recommendations
  class Processor
    class << self
      def process(params)
        recommender_implementation = Recommender::Base.get_implementation_for(params.type)
        recommender_implementation.new(params).recommendations
      end
    end
  end
end
