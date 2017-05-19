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
        Slavery.on_slave do
          # Если в это время был заказ, то не отправлять письмо
          return false if shop.orders.where(user_id: user.id).where('date >= ?', trigger_time_range.first).exists?

          # А теперь сразу несколько товаров – промежуточный шаг при переходе на Liquid-шаблонизатор
          actions = user.actions.where(shop: shop).carts.where(cart_date: trigger_time_range).order(cart_date: :desc).limit(10)
          if actions.exists?
            @happened_at = actions.first.cart_date
            @source_items = actions.map { |a| a.item.amount = a.cart_count; a.item }.map { |item| item if item.widgetable? }.compact
            @source_item = @source_items.first
            if @source_item
              return true
            end
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
