module TriggerMailings
  module Triggers
    class RecentlyPurchased < Base
      def condition_happened?
        time_range = (7.day.ago.beginning_of_day)..(7.day.ago.end_of_day)
        # Находим покупки, которые были сделаны 7 дней назад
        orders_relation = user.orders.where(shop: shop).where(date: time_range).order(date: :desc)
        orders_relation = orders_relation.successful if shop.track_order_status?

        orders_relation.each do |order|
          if order
            @happened_at = order.date
            @bought_item = order.order_items.map(&:item).sort { |i1, i2| (i1.price || 0) <=> (i2.price || 0) }.last
            return true
          end
        end
        return false
      end

      def recommended_ids(count)
        params = OpenStruct.new(
            shop: shop,
            user: user,
            limit: count,
            recommend_only_widgetable: true
        )

        # Сначала сопутку
        if @bought_item
          params.item = @bought_item
          params.locations = @bought_item.locations
          result = Recommender::Impl::AlsoBought.new(params).recommended_ids
        end

        # иногда в заказе нет купленного товара
        result ||= []

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
