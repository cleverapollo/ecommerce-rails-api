module TriggerMailings
  ##
  # Класс, ищущий триггеры
  #
  class TriggerDetector
    class << self
      # Найти триггер для пользователя в магазине
      # @param user [User] пользователь
      # @param shop [Shop] магазин
      #
      # @return [TriggerMailings::Triggers::Base] найденный триггер
      def detect(user, shop)
        triggers = triggers_implementations.map do |implementation|
          i = implementation.new(user, shop)
          i if i.happened?
        end.compact.sort{|x, y| x.rating <=> y.rating }.first
      end

      private

      # Массив реализаций триггеров
      #
      # @return [Array] массив реализаций триггеров
      # @private
      def triggers_implementations
        [TriggerMailings::Triggers::AbandonedCart,
         TriggerMailings::Triggers::RecentlyPurchased,
         TriggerMailings::Triggers::SlippingAway,
         TriggerMailings::Triggers::ViewedButNotBought]
      end
    end
  end
end
