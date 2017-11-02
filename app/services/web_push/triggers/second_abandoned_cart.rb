module WebPush
  module Triggers
    ##
    # Базовый класс для триггеров "брошенная корзина"
    #
    class SecondAbandonedCart < Base
      # Отправляем, если товар был положен в корзину больше 24 часов, но меньше 28 часов назад.
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

        actions = ActionCl.where(event: %w(cart remove_from_cart), shop_id: shop.id, session_id: user.sessions.where('updated_at >= ?', trigger_time_range.first.to_date).pluck(:id), created_at: trigger_time_range)
                      .where('date >= ?', trigger_time_range.first.to_date)
                      .order('date DESC, created_at DESC')
                      .select(:event, :object_id, :created_at)
                      .limit(100)
        return false if actions.blank?

        # Собираем массив товаров. Воспроизводим очередность событий, которая оставит то, что было в корзине
        items = []
        actions.reverse.each do |action|
          if action.event == 'cart'
            items << action.object_id
          end
          if action.event == 'remove_from_cart'
            items -= [action.object_id]
          end
        end

        # Достаем товары
        @happened_at = actions.first.created_at
        @items = shop.items.widgetable.available.where(uniqid: items)
        if @items.present?
          return true
        end

        false
      end

    end
  end
end
