module Recommender
  module Impl
    class SeeAlso < AlsoBought
      def check_params!
      end

      def items_which_cart_to_analyze
        # Берем все товары из корзины
        params.cart_item_ids
            #.first(3)
      end

      def inject_promotions(result, expansion_only = false, strict_categories = false)
        # Не надо включать промо
        result
      end
    end
  end
end
