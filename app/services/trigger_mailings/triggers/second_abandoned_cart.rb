module TriggerMailings
  module Triggers
    ##
    # Базовый класс для триггеров "брошенная корзина"
    #
    class SecondAbandonedCart < Base
      # Отправляем, если товар был положен в корзину больше часа, но меньше четырех часов назад.
      def trigger_time_range
        (28.hours.ago..24.hours.ago)
      end

      def priority
        100
      end

      def appropriate_time_to_send?
        true
      end

      def condition_happened?

        # Если в это время был заказ, то не отправлять письмо
        return false if shop.orders.where(user_id: user.id).where('date >= ?', trigger_time_range.first).exists?

        # Проверка что последное письмо отправили киленту 1 дня назад
        return false unless trigger_time_range.cover?(client.last_trigger_mail_sent_at)

        # Находим вчерашную не открытую брошеную корзину
        return false unless TriggerMail.where(shop: shop, opened: false, created_at: trigger_time_range, trigger_mailing_id: shop.trigger_abandoned_cart_id, client_id: client.id).exists?

        # Если корзины у клиента нет или она пустая (вдруг баг)
        return false if client.cart.nil? || client.cart.items.blank?

        # Достаем товары
        @happened_at = client.cart.date
        @source_items = shop.items.widgetable.available.where(id: client.cart.items)
        @source_item = @source_items.first
        if @source_item.present?
          return true
        end

        false
      end

      # Рекомендации для второй брошенной корзины
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
