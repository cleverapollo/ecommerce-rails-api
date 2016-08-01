module WebPush
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

      def condition_happened?

        # Если в это время был заказ, то не отправлять письмо
        return false if shop.orders.where(user_id: user.id).where('date >= ?', trigger_time_range.first).exists?

        # Проверка что последное письмо отправили киленту 1 дня назад
        return false if !trigger_time_range.cover?(client.last_web_push_sent_at)

        # Находим вчерашную не открытую брошеную корзину
        trigger_mailing = WebPushTrigger.where(shop: shop).find_by(trigger_type: 'abandoned_cart')
        return false unless WebPushTriggerMessage.where(shop: shop).where(created_at: trigger_time_range).where(clicked: false).where(web_push_trigger_id: trigger_mailing.id).where(client_id: client.id).exists?

        actions = user.actions.where(shop: shop).carts.where(cart_date: trigger_time_range).order(cart_date: :desc).limit(10)
        if actions.exists?
          @happened_at = actions.first.cart_date
          @items = actions.map { |a| a.item.amount = a.cart_count; a.item }.map { |item| item if item.widgetable? && item.is_available? }.compact
          return true if @items.any?
        end

        false
      end

    end
  end
end
