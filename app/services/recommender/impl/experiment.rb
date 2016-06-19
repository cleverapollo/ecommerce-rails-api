module Recommender
  module Impl
    class Experiment < Recommender::Impl::Interesting
      def items_to_recommend
        super
      end
    end
  end
end
