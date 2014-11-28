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
      def recommendations(count)
        return @shop.items.available.where("name is not null and name != '' and url is not null and url != '' and image_url is not null and image_url != '' and price is not null and price != 0.0").order('random()').limit(count).to_a

        #raise NotImplementedError
      end
    end
  end
end
