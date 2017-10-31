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
        Slavery.on_slave do

          # Если в это время был заказ, то не отправлять письмо
          return false if shop.orders.where(user_id: user.id).where('date >= ?', trigger_time_range.first).exists?

          # Проверка что последное письмо отправили киленту 1 дня назад
          return false unless trigger_time_range.cover?(client.last_trigger_mail_sent_at)

          # Находим вчерашную не открытую брошеную корзину
          return false unless TriggerMail.where(shop: shop, opened: false, created_at: trigger_time_range, trigger_mailing_id: shop.trigger_second_abandoned_cart_id, client_id: client.id).exists?

          # Смотрим, были ли события добавления / удаление в корзине в указанный промежуток
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
          @source_items = shop.items.widgetable.available.where(uniqid: items)
          @source_item = @source_items.first
          if @source_item.present?
            return true
          end

          false
        end
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
