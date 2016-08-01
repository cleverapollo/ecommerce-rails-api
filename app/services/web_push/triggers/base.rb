module WebPush
  module Triggers
    ##
    # Базовый класс, от которого наследуются реализации триггеров
    #
    class Base
      attr_accessor :shop, :user, :client, :happened_at, :items, :settings

      class << self
        # Код триггера
        # @return [String] код триггера
        def code
          self.name.split('::').last
        end

        def print_order
          WebPush::Triggers::NAMES.map { |x| "WebPush::Triggers::#{x}".constantize.new(Client.first) }.map { |x| [x.class.to_s, x.priority] }.sort_by { |x| x[1] }.reverse
        end

      end

      def mailing
        @mailing ||= shop.web_push_triggers.enabled.where(trigger_type: code.underscore).first!
      end

      def settings
        if @settings.blank?
          @settings = {
            subject: mailing.subject,
            message: mailing.message
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
      end

      # Проверка верхнего уровня - учитывает, включен ли триггер в настройках триггерных рассылок, можно ли сейчас слать письмо и случился ли триггер.
      # @return [Boolean] выполнен ли триггер
      def triggered?
        user.present? && condition_happened?
      end

      # Выполнено ли фактическое условие триггера - например, есть ли товар брошенной корзины.
      # @return [Boolean] выполнено ли условие
      def condition_happened?
        raise NotImplementedError
      end

      # Генерирует фейковые данные для отправки тестового триггера
      def generate_test_data!
        @happened_at = DateTime.current
        @items = shop.items.widgetable.limit 3
        true
      end

      # JSON триггера для сериализации
      # @return [String] JSON
      def to_json
        {
          happened_at: happened_at,
          items: items.to_json
        }.to_json
      end
    end
  end
end
