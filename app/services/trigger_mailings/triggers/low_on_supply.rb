module TriggerMailings
  module Triggers
    ##
    # Базовый класс для триггеров "У вас скоро закончится"
    #
    class LowOnSupply < Base

      # Берем заказы за последние два месяца и ищем там периодические товары.
      def trigger_time_range
        (2.months.ago..60.minutes.ago)
      end

      def priority
        10
      end

      def appropriate_time_to_send?
        true
      end

      def condition_happened?

        # Если магазину не разрешено использовать этот триггер, отменяем
        return false unless shop.supply_available?

        # Важно: отправляем триггер только в том случае, если ранее не отправляли.
        # Этот флаг стирается при каждом заказе пользователя
        return false if client.supply_trigger_sent?

        # TODO: отключить, когда будет готов триггер
        return false

        # Есть ли периодические товары, на которые должен сработать триггер?
        return find_periodic_products.any?

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




      private

      # Возвращает периодические товары, купленные покупателем за требуемых интервал времени.
      # Причем два одинаковых товара в разных заказах.
      # @return Item[]
      def find_periodic_products
        periodic_items = {} # { id: {dates: []} }
        Order.where(shop_id: shop.id).where(user_id: user.id).where(date: trigger_time_range).each do |order|
          order.order_items.includes(:item).each do |order_item|
            if order_item.item.periodic?
              if !periodic_items.key?(order_item.item_id)
                periodic_items[order_item.item_id] = []
              end
              periodic_items[order_item.item_id][] << { item: order_item.item, date: order.date.to_date }
            end
          end
        end

        # Выбираем только те, которые покупали больше одного раза
        appropriate_items = periodic_items.select { |k, v| v.count > 1 }.values

        # TODO Отсортировать даты в порядке покупок, чтобы первая дата была самой свежей

        # Рассчитываем средний интервал покупок
        appropriate_items.each do |k, history|
          appropriate_items[k][:period] = history # Тут что-то нужно написать. Видимо, отсортировать даты
        end

        # Оставляем только те, которые теоретически еще не закончились



        []
      end

    end
  end
end
