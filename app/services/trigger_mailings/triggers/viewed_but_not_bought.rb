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
          return true
        else
          return false
        end
      end

      def recommended_ids(count)
        # Сначала похожие товары
        result = Recommender::Impl::Similar.new(OpenStruct.new(
          shop: shop,
          user: user,
          item: source_item,
          limit: count,
          recommend_only_widgetable: true
        )).recommended_ids

        # Затем интересные
        if result.count < count
          result += Recommender::Impl::Interesting.new(OpenStruct.new(
            shop: shop,
            user: user,
            limit: count,
            exclude: result,
            recommend_only_widgetable: true
          )).recommended_ids
        end

        # Потом популярные
        if result.count < count
          result += Recommender::Impl::Popular.new(OpenStruct.new(
            shop: shop,
            user: user,
            limit: count,
            exclude: result,
            recommend_only_widgetable: true
          )).recommended_ids
        end

        result
      end

      def priority
        5
      end
    end
  end
end
