module WebPush
  module Triggers
    ##
    # Триггер "Пользователь долго не был активным".
    #
    class Retention < Base
      # Увязываем на действие, выполненное месяц назад.
      def trigger_time_range
        (1.month.ago.beginning_of_day.to_i..1.month.ago.end_of_day.to_i)
      end

      def priority
        5
      end

      # Условия:
      # 1. Последнее действие было месяц назад.
      # 2. После этого не было действий вообще.
      def condition_happened?
        if user.actions.where(shop: shop).where(timestamp: trigger_time_range).exists? && !user.actions.where(shop: shop).where('timestamp > ?', trigger_time_range.last).exists?
          @happened_at = 1.month.ago
          @items = Item.where(id: recommended_ids(1))
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
          recommend_only_widgetable: true
        )

        # Сначала интересные твоары
        result = Recommender::Impl::Interesting.new(params).recommended_ids

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
