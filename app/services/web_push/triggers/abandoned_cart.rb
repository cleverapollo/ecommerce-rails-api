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

        # Смотрим, были ли события добавления в корзину в указанный промежуток
        action = ActionCl.where(event: 'cart', shop_id: shop.id, session_id: user.sessions.where('updated_at >= ?', trigger_time_range.first.to_date).pluck(:id), created_at: trigger_time_range)
                     .where('date >= ?', trigger_time_range.first.to_date)
                     .order('date DESC, created_at DESC')
                     .limit(1).first
        return false if action.blank?

        # Ищем текущую корзину
        cart = ClientCart.find_by(shop: shop, user: user)
        return false if cart.blank? || cart.items.blank?

        # Достаем товары из корзины
        @happened_at = action.created_at
        @items = shop.items.widgetable.available.where(id: cart.items)
        if @items.present?
          return true
        end

        false
      end

    end
  end
end
