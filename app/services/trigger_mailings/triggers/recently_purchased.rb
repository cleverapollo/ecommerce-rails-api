module TriggerMailings
  module Triggers
    class RecentlyPurchased < Base
      def condition_happened?
        time_range = (4.day.ago.beginning_of_day)..(4.day.ago.end_of_day)
        # Находим покупки, которые были сделаны 4 дня назад
        if order = user.orders.where(shop: shop).where(date: time_range).order(date: :desc).first
          @happened_at = order.date
          @source_item = order.order_items.map(&:item)
          return true
        else
          return false
        end
      end

      def priority
        50
      end
    end
  end
end
