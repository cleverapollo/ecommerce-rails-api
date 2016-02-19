module TriggerMailings
  module Triggers
    class ViewedButNotBought < Base
      def condition_happened?
        time_start = (1.day.ago.beginning_of_day)
        time_range = time_start..(1.day.ago.end_of_day)

        if user.orders.where(date: time_start..Time.current).exists?
          return false
        end

        # Находим товар, который был вчера просмотрен самое большее число раз, но не был куплен
        user.actions.where(shop: shop).views.where(view_date: time_range).where('view_count > 0').order(view_count: :desc).each do |action|
          @happened_at = action.view_date
          @source_item = action.item
          @additional_info = action.view_count

          if @source_item.widgetable?
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
        5
      end
    end
  end
end
