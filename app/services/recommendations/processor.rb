module Recommendations
  class Processor
    class << self
      def process(params)
        if params.shop.active? && AbTesting.give_recommendations?(params.shop, params.user)
          recommender_implementation = Recommender::Base.get_implementation_for(params.type)
          recommender_implementation.new(params).recommendations
        else
          []
        end
      end
    end
  end
end
