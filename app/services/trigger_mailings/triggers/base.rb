module TriggerMailings
  module Triggers
    ##
    # Базовый класс, от которого наследуются реализации триггеров
    #
    class Base
      attr_accessor :shop, :user, :happened_at, :source_item, :additional_info

      class << self
        # Код триггера
        # @return [String] код триггера
        def code
          self.name.split('::').last
        end
      end

      # Код триггера
      # @return [String] код триггера
      def code
        self.class.code
      end

      # Конструктор
      # @param user [User] пользователь
      # @param shop [Shop] магазин
      def initialize(user, shop)
        @user = user
        @shop = shop
      end

      # Проверка верхнего уровня - учитывает, включен ли триггер в настройках триггерных рассылок, и случился ли триггер.
      # @return [Boolean] выполнен ли триггер
      def happened?
        enabled? && condition_happened?
      end

      # Включен ли триггер в настройках триггерных рассылок
      # @return [Boolean] включен ли триггер
      def enabled?
        @shop.trigger_mailing.trigger_settings[code]['enabled']
      end

      # Выполнено ли фактическое условие триггера - например, есть ли товар брошенной корзины.
      # @return [Boolean] выполнено ли условие
      def condition_happened?
        raise NotImplementedError
      end

      # Возвращает массив рекомендованных товаров для данного триггера.
      # @param count [Integer] необходимое количество рекомендаций
      #
      # @return [Array[Item]] массив рекомендованных товаров
      # @raise [TriggerMailings::NotEnoughRecommendationsError] триггер вернул слишком мало рекомендаций
      def recommendations(count)
        result = shop.items.available.widgetable.where(id: recommended_ids(count)).load
        if result.count < count
          binding.pry
          raise TriggerMailings::NotEnoughRecommendationsError.new("Expected #{count} recommendations, but given #{result.count}")
        end
        result
      end

      # Возвращает массив ID рекомендованных товаров для данного триггера.
      # @param count [Integer] необходимое количество рекомендаций
      #
      # @return [Array[Integer]] массив ID рекомендованных товаров
      def recommended_ids(count)
        raise NotImplementedError
      end

      # JSON триггера для сериализации
      #
      # @return [String] JSON
      def to_json
        {
          happened_at: happened_at,
          source_item: source_item.to_json,
          additional_info: additional_info.to_json
        }.to_json
      end
    end
  end

  class NotEnoughRecommendationsError < StandardError; end
end
