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

        # Смотрим, были ли события добавления в корзину в указанный промежуток
        action = ActionCl.where(event: 'cart', shop_id: shop.id, session_id: user.active_session_ids(trigger_time_range.first.to_date))
                     .in_date(trigger_time_range)
                     .order('date DESC, created_at DESC')
                     .limit(1).first
        return false if action.blank?

        # Ищем текущую корзину
        cart = ClientCart.find_by(shop: shop, user: user)
        return false if cart.blank?

        # Достаем товары из корзины
        @happened_at = action.created_at
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
