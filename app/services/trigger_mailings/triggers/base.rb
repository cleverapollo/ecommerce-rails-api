module TriggerMailings
  module Triggers
    ##
    # Базовый класс, от которого наследуются реализации триггеров
    #
    class Base
      # @return [Shop]
      attr_accessor :shop
      # @return [User]
      attr_accessor :user
      # @return [Client]
      attr_accessor :client
      attr_accessor :happened_at, :source_item, :source_items, :additional_info, :search_query

      class << self
        # Код триггера
        # @return [String] код триггера
        def code
          self.name.split('::').last
        end

        def print_order
          TriggerMailings::Triggers::NAMES.map { |x| "TriggerMailings::Triggers::#{x}".constantize.new(Client.first) }.map { |x| [x.class.to_s, x.priority] }.sort_by { |x| x[1] }.reverse
        end

      end

      def mailing
        @mailing ||= shop.trigger_mailings.where(trigger_type: code.underscore).first!
      end

      def settings
        if @settings.blank?
          @settings = {
            send_from: shop.mailings_settings.send_from,
            subject: mailing.subject,
            liquid_template: mailing.liquid_template,
            text_template: mailing.text_template,
            amount_of_recommended_items: mailing.amount_of_recommended_items,
            images_dimension: mailing.images_dimension
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
        Rails.logger.debug "\e[1m\e[35m[trigger] \e[32m#{self.class}\e[0m"
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
        # Не учитывает часовой пояс покупателя, поэтому пока отключил.
        # (Time.now.hour >= 10) && (Time.now.hour < 22)
        true
      end

      # Возвращает массив рекомендованных товаров для данного триггера.
      # @param count [Integer] необходимое количество рекомендаций
      #
      # @return [Array[Item]] массив рекомендованных товаров
      def recommendations(count)
        ids = recommended_ids(count)
        items_list = Slavery.on_slave { shop.items.recommendable.widgetable.where(id: ids).load }
        items_list.sort_by do |element|
          ids.index(element.id)
        end
        items_list
      end

      # Генерирует фейковые данные для отправки тестового триггера
      def generate_test_data!(recommended_items = 12)
        Slavery.on_slave do
          @happened_at = DateTime.current
          @source_items = shop.items.recommendable.widgetable.limit(recommended_items)
          @source_item = shop.items.recommendable.widgetable.limit(1)[0]
          @additional_info[:categories] = ItemCategory.where(shop_id: shop.id, external_id: shop.items.available.recommendable.widgetable.limit(5).pluck(:category_ids).flatten.uniq.compact)
          @additional_info[:test] = true
          if self.kind_of? RecentlyPurchased
            @additional_info[:order] = shop.orders.first
          end
          true
        end
      end

      # Current trigger type, for example :second_abandoned_cart
      # @return [Symbol]
      def type
        self.class.to_s.gsub(/\A(.+::)(.+)\z/, '\2').underscore.to_sym
      end

      # Отправляет триггерное письмо
      # @param [Client] client
      # @param [Mailings::GetResponseClient] get_response_client
      def letter(client, get_response_client = nil)
        if shop.mailings_settings.external_getresponse?
          TriggerMailings::GetResponseLetter.new(client, self, get_response_client).send
        elsif shop.mailings_settings.external_ofsys?
          result = TriggerMailings::OfsysLetter.new(client, self).send
          return unless result
        elsif shop.mailings_settings.is_optivo_for_mytoys?
          TriggerMailings::OptivoMytoysLetter.new(client, self).send
        elsif shop.mailings_settings.external_mailganer?
          TriggerMailings::MailganerLetter.new(client, self).send
        elsif shop.mailings_settings.external_mailchimp?
          # Здесь для маилчимпа ничего не нужно делать
          return
        else
          begin
            TriggerMailings::Letter.new(client, self).send
          rescue TriggerMailings::Letter::EmptyProductsCollectionError => e
            # Если вдруг не было товаров к рассылке, то просто ничего не делаем. Письмо в базе остается как будто отправленное.
            # Костыль, конечно, но пока так.
            Rails.logger.warn e
          end
        end
        unless shop.mailings_settings.external_mailchimp?
          client.shop_email.update_columns(last_trigger_mail_sent_at: Time.now)
          client.update_columns(supply_trigger_sent: true) if self.class == TriggerMailings::Triggers::LowOnSupply
        end
      end

      # Возвращает массив ID рекомендованных товаров для данного триггера.
      # Применяется в методе recommendations. В нем содержится вся логика товарных рекомендаций в конкретных реализациях
      # триггеров.
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
