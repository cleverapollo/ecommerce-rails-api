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
        end.compact.sort{|x, y| x.priority <=> y.priority }.last
      end

      private

      # Массив реализаций триггеров
      #
      # @return [Array] массив реализаций триггеров
      # @private
      def triggers_implementations
        TriggerMailings::Triggers::NAMES.map do |trigger|
          "TriggerMailings::Triggers::#{trigger}".constantize
        end
      end
    end
  end
end
