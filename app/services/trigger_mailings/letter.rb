module TriggerMailings
  ##
  # Класс, реализующий триггерное письмо
  #
  class Letter
    class IncorrectMailingSettingsError < StandardError; end

    attr_accessor :client, :trigger, :trigger_mail

    # Конструктор
    # @param client [Client] пользователь магазина
    # @param trigger [TriggerMailings::Triggers::Base] триггер
    def initialize(client, trigger)
      @client = client
      @shop = @client.shop
      @trigger = trigger
      @trigger_mail = client.trigger_mails.create!(
        mailing: trigger.mailing,
        shop: client.shop,
        trigger_data: {
          trigger: trigger.to_json
        }
      ).reload
      @body = generate_letter_body
    end

    # Отправить сформированное письмо
    def send
      email = client.email
      #email = 'anton.zhavoronkov@mkechinov.ru'
      Mailings::SignedEmail.compose(@shop, to: email,
                                    subject: trigger.settings[:subject],
                                    from: trigger.settings[:send_from],
                                    body: @body,
                                    type: 'trigger',
                                    code: trigger_mail.code).deliver_now
    end

    private

    # Сформировать тело письма
    #
    # @return [String] тело письма
    # @private
    def generate_letter_body
      result = trigger.settings[:template].dup
      # Узнаем количество необходимых рекомендаций
      recommendations_count = trigger.settings[:template].scan(/{{ recommended_item }}/).count

      # Вставляем в шаблон параметры "исходного" товара
      if trigger.source_item.present?
        decorated_source_item = item_for_letter(trigger.source_item)

        decorated_source_item.each do |key, value|
          result.gsub!("{{ source_item.#{key} }}", value)
        end
      end

      RecommendationsRequest.report do |r|
        recommendations = trigger.recommendations(recommendations_count)

        # Проходимся по рекомендациям и вставляем их в шаблон
        recommendations.each do |recommended_item|
          decorated_recommended_item = item_for_letter(recommended_item)

          recommended_item_template = trigger.settings[:item_template].dup
          decorated_recommended_item.each do |key, value|
            recommended_item_template.gsub!("{{ #{key} }}", value)
          end

          result['{{ recommended_item }}'] = recommended_item_template
        end

        # Убираем оставшиеся метки, если рекомендаций вернулось меньше, чем нужно
        result.gsub!('{{ recommended_item }}', '')

        r.shop = @shop
        r.recommender_type = 'trigger_mail'
        r.recommendations = recommendations.map(&:uniqid)
        r.user_id = client.user.present? ? client.user.id : 0
      end



      # Ставим utm-параметры
      result.gsub!('{{ utm_params }}', Mailings::Composer.utm_params(trigger_mail, as: :string))

      # В конце прицепляем футер на отписку
      footer = Mailings::Composer.footer(email: client.email,
                                         tracking_url: trigger_mail.tracking_url,
                                         unsubscribe_url: client.trigger_unsubscribe_url)
      result.gsub!('{{ footer }}', footer)

      result
    end

    # Обертка над товаром для отображения в письме
    # @param [Item] товар
    #
    # @raise [Mailings::NotWidgetableItemError] исключение, если у товара нет необходимых параметров
    # @return [Hash] обертка
    def item_for_letter(item)
      raise Mailings::NotWidgetableItemError.new(item) unless item.widgetable?
      {
        name: item.name.truncate(40),
        description: item.description.to_s.truncate(130),
        price: item.price.round.to_s,
        url: UrlHelper.add_params_to(item.url, Mailings::Composer.utm_params(trigger_mail)),
        image_url: item.image_url
      }
    end
  end
end
