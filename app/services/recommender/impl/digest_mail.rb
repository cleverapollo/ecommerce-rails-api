module Recommender
  module Impl
    ##
    # Псевдокласс-рекомендер. Нужен для трекинга покупок с дайджестных писем.
    #
    class DigestMail < Recommender::Raw
      def recommended_ids
        raise NotImplementedError
      end
    end
  end
end
