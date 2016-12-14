module TriggerMailings
  module Triggers
    class ViewedButNotBought < Base
      def condition_happened?
        time_start = (1.day.ago.beginning_of_day)
        time_range = time_start..(1.day.ago.end_of_day)

        if user.orders.where(date: time_start..Time.current).exists?
          return false
        end

        # Если недавно был заказ, триггер не шлем.
        # http://y.mkechinov.ru/issue/REES-3399
        return false if user.orders.where('date >= ?', 7.days.ago).exists?

        # Находим товар, который был вчера просмотрен самое большее число раз, но не был куплен
        actions = user.actions.where(shop: shop).views.where(view_date: time_range).where('view_count > 0').order(view_count: :desc).limit(10)
        if actions.exists?
          @happened_at = actions.first.view_date
          @source_items = actions.map { |a| a.item if a.item.widgetable? }.compact
          @source_item = @source_items.first
          if @source_item.present?
            return true
          end
        end

        return false
      end

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

      def priority
        15
      end
    end
  end
end
