module TriggerMailings
  module Events
    class ViewedButNotBought < Base
      def happened?
        time_range = (1.day.ago.beginning_of_day)..(1.day.ago.end_of_day)
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

      def priority
        5
      end
    end
  end
end
