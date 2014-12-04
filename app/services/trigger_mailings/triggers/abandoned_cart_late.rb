module TriggerMailings
  module Triggers
    ##
    # Поздняя реакция на брошенную корзину.
    #
    class AbandonedCartLate < AbandonedCartBase
      # Отправляем, если товар был положен в корзину больше суток, но меньше двух назад.
      def trigger_time_range
        (48.hours.ago..24.hours.ago)
      end

      # Приоритет чуть ниже, чем у ранней корзины.
      def priority
        10
      end
    end
  end
end
