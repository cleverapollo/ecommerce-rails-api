module TriggerMailings
  module Triggers
    class SlippingAway < Base
      def condition_happened?
        # Юзер не заходил на сайт три месяца
        if user.actions.where(shop: shop).any? && user.actions.where(shop: shop).where('view_date >= ?', 3.month.ago).none?
          return true
        else
          return false
        end
      end

      def priority
        1
      end
    end
  end
end
