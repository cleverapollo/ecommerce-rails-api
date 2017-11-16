module TriggerMailings
  module Triggers
    ##
    # Триггер "Пользователь долго не был активным".
    #
    class Retention < Base
      # Увязываем на действие, выполненное месяц назад.
      def trigger_time_range
        (1.month.ago.beginning_of_day.to_date..1.month.ago.end_of_day.to_date)
      end

      def priority
        5
      end

      def appropriate_time_to_send?
        true
      end

      # Условия:
      # 1. Последнее действие было месяц назад.
      # 2. После этого не было действий вообще.
      def condition_happened?
        sessions = user.active_session_ids(trigger_time_range.first.to_date)
        actions_in_range = ActionCl.where(shop_id: shop.id, session_id: sessions, date: trigger_time_range.first).exists?
        actions_over_range = ActionCl.where(shop_id: shop.id, session_id: sessions).where('date > ?', trigger_time_range.last).exists?

        if actions_in_range && !actions_over_range
          Slavery.on_slave do

            @happened_at = 1.month.ago
            @source_items = []

            @bought_item = []
            orders_relation = user.orders.where(shop: shop) #.where(date: trigger_time_range)
            orders_relation = orders_relation.successful if shop.track_order_status?
            orders_relation.each do |order|
              @bought_item << Item.where(id: order.order_items.pluck(:item_id)).pluck(:uniqid)
            end

          end

          return true
        end
        false
      end

      # Рекомендации для долгой неактивности:
      # 1. Интересные.
      # 2. Популярные.
      def recommended_ids(count)

        params = OpenStruct.new(
          shop: shop,
          user: user,
          limit: count,
          recommend_only_widgetable: true,
          exclude: @bought_item.try(:flatten).try(:uniq)
        )

        # Сначала интересные твоары
        result = Recommender::Impl::Interesting.new(params).recommended_ids

        # Потом популярные
        if result.count < count
          result += Recommender::Impl::Popular.new(params.tap { |p|
            p.limit = (count - result.count)
            p.exclude += result
          }).recommended_ids
        end

        result
      end
    end
  end
end
