module TriggerMailings
  module Triggers
    ##
    # Триггер "Брошенный просмотр категории"
    #
    class AbandonedCategory < Base
      # Отправляем, если товар был положен в корзину больше часа, но меньше четырех часов назад.
      def trigger_time_range
        (240.minutes.ago.to_i..60.minutes.ago.to_i)
      end

      def priority
        13
      end

      def appropriate_time_to_send?
        true
      end

      # Есть ли хотя бы одно действие месяц назад?
      # @return Boolean
      def condition_happened?
        return false # TODO доделать триггер
        if user.actions.where(shop: shop).where(timestamp: trigger_time_range).exists?
          @source_items = []
          return true
        end
        false
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
    end
  end
end
