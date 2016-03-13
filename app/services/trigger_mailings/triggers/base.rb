module TriggerMailings
  module Triggers
    ##
    # Базовый класс, от которого наследуются реализации триггеров
    #
    class Base
      attr_accessor :shop, :user, :client, :happened_at, :source_item, :source_items, :additional_info

      class << self
        # Код триггера
        # @return [String] код триггера
        def code
          self.name.split('::').last
        end
      end

      def mailing
        @mailing ||= shop.trigger_mailings.enabled.where(trigger_type: code.underscore).first!
      end

      def settings
        if @settings.blank?
          @settings = {
            send_from: shop.mailings_settings.send_from,
            subject: mailing.subject,
            template: mailing.template,
            item_template: mailing.item_template,
            source_item_template: mailing.source_item_template
          }
        end

        @settings
      end

      # Код триггера
      # @return [String] код триггера
      def code
        self.class.code
      end


      # Конструктор
      # @param client [Client] пользователь магазина
      def initialize(client)
        @user = client.user
        @shop = client.shop
        @client = client
        @additional_info = {}
      end

      # Проверка верхнего уровня - учитывает, включен ли триггер в настройках триггерных рассылок, можно ли сейчас слать письмо и случился ли триггер.
      # @return [Boolean] выполнен ли триггер
      def triggered?
        appropriate_time_to_send? && user.present? && condition_happened?
      end

      # Выполнено ли фактическое условие триггера - например, есть ли товар брошенной корзины.
      # @return [Boolean] выполнено ли условие
      def condition_happened?
        raise NotImplementedError
      end

      # Подходящее ли сейчас время, чтобы отправлять письмо?
      # По умолчанию, отправляем письма с 10 до 22
      #
      # @return [Boolean] можно ли отправлять письмо
      def appropriate_time_to_send?
        (Time.now.hour >= 10) && (Time.now.hour < 22)
      end

      # Возвращает массив рекомендованных товаров для данного триггера.
      # @param count [Integer] необходимое количество рекомендаций
      #
      # @return [Array[Item]] массив рекомендованных товаров
      def recommendations(count)
        ids = recommended_ids(count)
        items_list = shop.items.recommendable.widgetable.where(id: ids).load
        items_list.sort_by do |element|
          ids.index(element.id)
        end
        items_list
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
end
