module Recommender
  module Impl
    class SeeAlso < AlsoBought
      def check_params!
      end

      def items_which_cart_to_analyze
        params.cart_item_ids
      end
    end
  end
end
