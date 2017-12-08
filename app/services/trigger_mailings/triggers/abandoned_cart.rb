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
        40
      end

      def appropriate_time_to_send?
        true
      end

      def condition_happened?

        # Если в это время был заказ, то не отправлять письмо
        return false if shop.orders.where(user_id: user.id).where('date >= ?', trigger_time_range.first).exists?

        # Ищем текущую корзину
        cart = ClientCart.find_by(shop: shop, user: user)

        # Выходим, если корзины нет или в корзине нет товаров или дата обновления не входит в диапазон
        return false if cart.blank? || cart.items.blank? || !trigger_time_range.cover?(cart.updated_at)

        # Достаем товары из корзины
        @happened_at = cart.updated_at
        @source_items = shop.items.widgetable.available.where(id: cart.items)
        @source_item = @source_items.first
        if @source_item.present?
          return true
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
