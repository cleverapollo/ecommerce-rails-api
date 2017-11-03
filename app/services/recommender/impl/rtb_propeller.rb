module Recommender
  module Impl
    ##
    # Псевдокласс-рекомендер. Нужен для трекинга покупок с RTB.
    #
    class RtbPropeller < Recommender::Raw
      def recommended_ids
        raise NotImplementedError
      end
    end
  end
end
