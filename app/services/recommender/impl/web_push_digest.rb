module Recommender
  module Impl
    ##
    # Псевдокласс-рекомендер. Нужен для трекинга покупок с триггерных писем.
    #
    class WebPushDigest < Recommender::Raw
      def recommended_ids
        raise NotImplementedError
      end
    end
  end
end
