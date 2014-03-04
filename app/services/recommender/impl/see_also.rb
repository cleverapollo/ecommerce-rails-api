module Recommender
  module Impl
    class SeeAlso < Recommender::Filtered
      def items_to_estimate
        params.cart_item_ids
      end
    end
  end
end
