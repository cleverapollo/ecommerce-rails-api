module Recommender
  module Impl
    class SeeAlso < AlsoBought
      def check_params!
        raise Recommendations::IncorrectParams.new('Cart IDs required for this recommender') if params.cart_item_ids.none?
      end

      def items_which_cart_to_analyze
        params.cart_item_ids
      end
    end
  end
end
