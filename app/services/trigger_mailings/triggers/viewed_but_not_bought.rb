module TriggerMailings
  module Triggers
    class ViewedButNotBought < Base
      def condition_happened?
        time_start = (1.day.ago.beginning_of_day)
        time_range = time_start..(1.day.ago.end_of_day)

        if user.orders.where(date: time_start..Time.current).any?
          return false
        end

        # Находим товар, который был вчера просмотрен самое большее число раз, но не был куплен
        if action = user.actions.where(shop: shop).views.where(view_date: time_range).where('view_count > 1').order(view_count: :desc).first
          @happened_at = action.view_date
          @source_item = action.item
          @additional_info = action.view_count
          return @source_item.widgetable?
        else
          return false
        end
      end

      def recommended_ids(count)
        params = OpenStruct.new(
          shop: shop,
          user: user,
          item: source_item,
          limit: count,
          recommend_only_widgetable: true
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
        5
      end
    end
  end
end
