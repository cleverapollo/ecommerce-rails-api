module Recommender
  module Impl
    class AlsoBought < Recommender::Filtered
      def items_to_filter
        params.item.id
      end
    end
  end
end
