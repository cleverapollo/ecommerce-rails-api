module TriggerMailings
  module Triggers
    ##
    # Ранняя реакция на брошенную корзину.
    #
    class AbandonedCartEarly < AbandonedCartBase
      # Отправляем, если товар был положен в корзину больше часа, но меньше двух назад.
      def trigger_time_range
        (120.minutes.ago..60.minutes.ago)
      end

      # Приоритет чуть выше, чем у поздней корзины.
      def priority
        11
      end

      # Ранние письма о корзине отправляем в любом случае.
      def appropriate_time_to_send?
        true
      end
    end
  end
end
