module TriggerMailings
  module Triggers
    class RecentlyPurchased < Base
      def condition_happened?
        time_range = (4.day.ago.beginning_of_day)..(4.day.ago.end_of_day)
        # Находим покупки, которые были сделаны 4 дня назад
        if order = user.orders.where(shop: shop).where(date: time_range).order(date: :desc).first
          @happened_at = order.date
          @source_item = order.order_items.map(&:item).sort{|i1, i2| i1.price <=> i2.price }.last
          return true
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

        # Сначала сопутку
        result = Recommender::Impl::AlsoBought.new(params).recommended_ids

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
        50
      end
    end
  end
end
