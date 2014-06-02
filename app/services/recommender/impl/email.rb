module Recommender
  module Impl
    class Email < Recommender::Raw
      def recommended_ids
        raise 'Not supposed to be called'
      end
    end
  end
end
