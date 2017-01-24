module TriggerMailings
  module Triggers
    ##
    # Триггер "Брошенный поиск".
    #
    class AbandonedSearch < Base

      # Интервал целочисленных значений (timestamp), в котором должно произойти ожидаемое событие для триггера.
      # @return Range
      def trigger_time_range
        (48.hours.ago.to_i..60.minutes.ago.to_i)
      end

      def priority
        7
      end

      # Используется для определения подходящего времени суток, года или даты
      def appropriate_time_to_send?
        true
      end

      # Условия:
      # Есть поисковый запрос за сегодня.
      # Были действия за нужный интервал времени.
      # Не было покупок за сегодня.
      def condition_happened?
        # Были поисковые запросы сегодня?
        if (search_queries = user.search_queries.where(date: Date.current).where(shop: shop).order(id: :desc)).any?
          @search_query = search_queries.first.query
          # Не было покупок за сутки?
          if !user.orders.where(shop: shop).where('date > ? ', 2.days.ago).exists?
            # Были действия за указанный указанный промежуток времени?
            if user.actions.where(shop: shop).where(timestamp: trigger_time_range).exists?
              @source_items = []
              return true
            end
          end
        end

        false
      end

      # Метод возвращает товарные рекомендации для триггера
      # @param count [Integer] Количество рекомендаций
      # @return Array
      def recommended_ids(count)
        params = OpenStruct.new(
          shop: shop,
          user: user,
          search_query: @search_query,
          limit: count,
          recommend_only_widgetable: true,
          locations: client.location.present? ? [client.location] : nil
        )

        # Сначала "недавний поиск"
        result = Recommender::Impl::Search.new(params).recommended_ids

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
