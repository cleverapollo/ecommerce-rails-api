module WebPush
  module Triggers
    ##
    # Базовый класс для триггеров "У вас скоро закончится"
    #
    class LowOnSupply < Base

      # Берем заказы за последние два месяца и ищем там периодические товары.
      def trigger_time_range
        (2.months.ago..60.minutes.ago)
      end

      # Приоритетнее недавней покупки
      def priority
        55
      end

      def condition_happened?

        # Важно: отправляем триггер только в том случае, если ранее не отправляли.
        # Этот флаг стирается при каждом заказе пользователя
        return false if client.supply_trigger_sent?

        # Есть ли периодические товары, на которые должен сработать триггер?
        return find_periodic_products.any?

      end


      private

      # Возвращает периодические товары, купленные покупателем за требуемых интервал времени.
      # Причем два одинаковых товара в разных заказах.
      # @return Item[]
      def find_periodic_products
        periodic_items = {}
        Order.where(shop_id: shop.id).where(user_id: user.id).where(date: trigger_time_range).each do |order|
          order.order_items.includes(:item).each do |order_item|
            if order_item.item.present? && order_item.item.periodic? && order_item.item.is_available? && order_item.item.widgetable? && !order_item.item.ignored?
              if !periodic_items.key?(order_item.item_id)
                periodic_items[order_item.item_id] = []
              end
              periodic_items[order_item.item_id] << order.date.to_date
            end
          end
        end

        # Оставляем только уникальные даты, чтобы не учитывать заказы в один день
        periodic_items.each { |k, v| periodic_items[k].uniq! }

        # Выбираем только те, которые покупали больше одного раза
        periodic_items.delete_if { |k, v| v.count < 2 }

        # Отсортировать даты в порядке покупок, чтобы первая дата была самой свежей
        periodic_items.each { |k, v| periodic_items[k].sort! }

        # Ищем финальный список товаров, дата покупки которых либо закончилась либо закончится через 5 дней, но не более 20% от интервала покупки (если интервал покупки 5 дней, то не более 1 дня)
        final_ids = []
        periodic_items.each do |id, dates|

          # Посчитаем средний интервал покупок
          diffs = []
          dates.each_index do |i|
            diffs << dates[i+1].to_time.to_i - dates[i].to_time.to_i if i < (dates.length - 1)
          end
          interval = diffs.inject{ |sum, el| sum + el }.to_f / diffs.size

          # Рассчитываем дату, когда товар должен закончиться
          deadline = dates.last + interval.seconds

          # Если дата в прошлом либо наступит через 5 дней
          if deadline < (DateTime.current + 5.days)
            final_ids << id
          end

        end

        @items = Item.where(shop_id: shop.id).widgetable.recommendable.where(id: final_ids).limit 1

        @items.limit(1).pluck(:id)
      end

    end
  end
end
