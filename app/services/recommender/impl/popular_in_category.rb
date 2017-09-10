module Recommender
  module Impl
    ##
    # Псевдокласс-рекомендер
    #
    class PopularInCategory < Recommender::Raw
      def recommended_ids
        raise NotImplementedError
      end
    end
  end
end
