module TriggerMailings
  module Triggers
    ##
    # Базовый класс для триггеров "брошенная корзина"
    #
    class AbandonedCart < Base
      # Отправляем, если товар был положен в корзину больше часа, но меньше четырех часов назад.
      def trigger_time_range
        (240.minutes.ago..60.minutes.ago)
      end

      def priority
        11
      end

      def appropriate_time_to_send?
        true
      end

      def condition_happened?
        # Находим товар, который был положен в корзину в нужном периоде, но не был из нее удален или куплен
        user.actions.where(shop: shop).carts.where(cart_date: trigger_time_range).order(cart_date: :desc).each do |action|
          @happened_at = action.cart_date
          @source_item = action.item

          if @source_item.present? && @source_item.widgetable?
            return true
          end
        end
        false
      end

      # Рекомендации для брошенной корзины
      def recommended_ids(count)
        params = OpenStruct.new(
          shop: shop,
          user: user,
          item: source_item,
          limit: count,
          recommend_only_widgetable: true,
          locations: source_item.locations
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
