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

      def inject_promotions(result)
        # Не надо включать промо
        result
      end
    end
  end
end
