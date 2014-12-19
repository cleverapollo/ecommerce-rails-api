module TriggerMailings
  module Triggers
    ##
    # Базовый класс для триггеров "брошенная корзина"
    #
    class AbandonedCartBase < Base
      # Период времени, за который нужно обнаружить брошенную корзину. Должен быть реализован в дочернем классе.
      #
      # @return [Range] период времени
      # @raise [NotImplementerError] ошибка, если метод не реализован в дочернем классе
      def trigger_time_range
        raise NotImplementedError
      end

      def condition_happened?
        # Находим товар, который был положен в корзину в нужном периоде, но не был из нее удален или куплен
        if action = user.actions.where(shop: shop).carts.where(cart_date: trigger_time_range).order(cart_date: :desc).first
          @happened_at = action.cart_date
          @source_item = action.item
        end
        @source_item.present? && @source_item.widgetable?
      end

      # Рекомендации для брошенной корзины
      def recommended_ids(count)
        params = OpenStruct.new(
          shop: shop,
          user: user,
          item: source_item,
          limit: count,
          recommend_only_widgetable: true
        )

        # Сначала похожие товары
        result = Recommender::Impl::Similar.new(params).recommended_ids

        # Затем интересные
        if result.count < count
          result += Recommender::Impl::Interesting.new(params.tap { |p|
            p.limit = (count - result.count)
            p.exclude = result
          }).recommended_ids
        end

        # Потом популярные
        if result.count < count
          result += Recommender::Impl::Popular.new(params.tap { |p|
            p.limit = (count - result.count)
            p.exclude = result
          }).recommended_ids
        end

        result
      end
    end
  end
end
