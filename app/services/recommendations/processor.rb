##
# Обработчик рекомендаций
#
module Recommendations
  class Processor
    class << self
      def process(params)
        result = []
        if params.shop.active? && AbTesting.give_recommendations?(params.shop, params.user)
          RecommendationsRequest.report do |r|
            recommender_implementation = Recommender::Base.get_implementation_for(params.type)
            result = recommender_implementation.new(params).recommendations

            r.shop = params.shop
            r.recommender_type = params.type
            r.recommendations = result
            r.user = params.user
            r.session = params.session
          end
        end
        result
      end
    end
  end
end
