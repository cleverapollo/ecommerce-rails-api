module TriggerMailings
  module Triggers
    class AbandonedCart < Base
      def condition_happened?
        time_range = (1.day.ago.beginning_of_day)..(1.day.ago.end_of_day)
        # Находим товар, который был вчера положен в корзину, но не был из нее удален или куплен
        if action = user.actions.where(shop: shop).carts.where(cart_date: time_range).order(cart_date: :desc).first
          @happened_at = action.cart_date
          @source_item = action.item
          return true
        else
          return false
        end
      end

      # Рекомендации для брошенной корзины
      def recommended_ids(count)
        # Сначала похожие товары
        result = Recommender::Impl::Similar.new(OpenStruct.new(
          shop: shop,
          user: user,
          item: source_item,
          limit: count,
          recommend_only_widgetable: true
        )).recommended_ids

        # Затем интересные
        if result.count < count
          result += Recommender::Impl::Interesting.new(OpenStruct.new(
            shop: shop,
            user: user,
            limit: count,
            exclude: result,
            recommend_only_widgetable: true
          )).recommended_ids
        end

        # Потом популярные
        if result.count < count
          result += Recommender::Impl::Popular.new(OpenStruct.new(
            shop: shop,
            user: user,
            limit: count,
            exclude: result,
            recommend_only_widgetable: true
          )).recommended_ids
        end

        result
      end

      def priority
        10
      end
    end
  end
end
