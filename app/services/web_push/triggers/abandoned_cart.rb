module WebPush
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

      def condition_happened?

        # Если в это время был заказ, то не отправлять письмо
        return false if shop.orders.where(user_id: user.id).where('date >= ?', trigger_time_range.first).exists?

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
