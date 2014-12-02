module TriggerMailings
  ##
  # Класс, реализующий триггерное письмо
  #
  class Letter
    class NotWidgetableItemError < StandardError; end
    class IncorrectMailingSettingsError < StandardError; end

    attr_accessor :subscription, :trigger, :trigger_mail

    # Конструктор
    # @param subscription [Subscription] подписка
    # @param trigger [TriggerMailings::Triggers::Base] триггер
    def initialize(subscription, trigger)
      @subscription = subscription
      @trigger = trigger
      @trigger_mail = subscription.trigger_mails.create!(
        shop: subscription.shop,
        trigger_code: trigger.code,
        trigger_data: {
          trigger: trigger.to_json
        }
      ).reload
      @body = generate_letter_body
    end

    # Отправить сформированное письмо
    def send
      Mailer.digest(
        #email: email,
        email: 'anton.zhavoronkov@mkechinov.ru',
        subject: subject,
        send_from: send_from,
        body: body
      ).deliver
    end

    private

    # Сформировать тело письма
    #
    # @return [String] тело письма
    # @private
    def generate_letter_body
      result = settings['template'].dup
      # Узнаем количество необходимых рекомендаций
      recommendations_count = settings['template'].scan(/{{ recommended_item }}/).count

      # Вставляем в шаблон параметры "исходного" товара
      if trigger.source_item.present?
        decorated_source_item = item_for_letter(trigger.source_item)

        decorated_source_item.each do |key, value|
          result.gsub!("{{ source_item.#{key} }}", value)
        end
      end

      # Проходимся по рекомендациям и вставляем их в шаблон
      trigger.recommendations(recommendations_count).each do |recommended_item|
        decorated_recommended_item = item_for_letter(recommended_item)

        recommended_item_template = settings['item_template'].dup
        decorated_recommended_item.each do |key, value|
          recommended_item_template.gsub!("{{ item.#{key} }}", value)
        end

        result['{{ recommended_item }}'] = recommended_item_template
      end

      # В конце прицепляем футер на отписку
      result.gsub!('{{ footer }}', footer)

      result
    end

    # Футер для письма
    #
    # @return [String] футе
    def footer
      host = Rails.env.production? ? 'api.rees46.com' : '127.0.0.1:8080'
      unsubscribe_url = Rails.application.routes.url_helpers.unsubscribe_subscriptions_url(unsubscribe_token: subscription.unsubscribe_token, host: host)
      tracking_pixel = Rails.application.routes.url_helpers.track_trigger_mail_url(trigger_mail_code: trigger_mail.code, host: host)
      <<-HTML
        <div style='max-width:600px; margin:0 auto 40px; padding:20px 0 0; font-family:sans-serif; color:#666; font-size:12px; line-height:20px; text-align:left;'>
          Сообщение было отправлено на <a href='mailto:#{subscription.email}' style='color:#064E86;'><span style='color:#064E86;'>#{subscription.email}</span></a>, адрес был подписан на рассылки <a href='http://rees46.com/' target='_blank' style='color:#064E86;'><span style='color:#064E86;'>REES46</span></a>.
          <br>
          Если вы не хотите получать подобные письма, вы можете <a href='#{unsubscribe_url}' style='color:#064E86;'><span style='color:#064E86;'>отписаться от рассылки</span></a>.
        </div>
        <img src='#{tracking_pixel}'></img>
      HTML
    end

    # Обертка над товаром для отображения в письме
    # @param [Item] товар
    #
    # @raise [TriggerMailings::Letter::NotWidgetableItemError] исключение, если у товара нет необходимых параметров
    # @return [Hash] обертка
    def item_for_letter(item)
      raise NotWidgetableItemError.new(item.id) unless item.widgetable?
      {
        name: item.name,
        price: item.price.to_s,
        url: UrlHelper.add_params_to(item.url, utm_source: 'rees46', utm_meta: 'trigger_mail', utm_campaign: @trigger.code, rees46_trigger_mail_code: trigger_mail.code),
        image_url: item.image_url
      }
    end

    # Ссылка на настройки текущего триггера
    #
    # @return [Hash] настройки текущего триггера
    # @private
    def settings
      @subscription.shop.trigger_mailing.trigger_settings[@trigger.code]
    end

    # E-mail текущего получателя
    #
    # @return [String] e-mail текущего получателя
    # @private
    def email
      @subscription.email
    end

    # Заголовок текущего письма
    #
    # @return [String] заголовок текущего письма
    # # @raise [TriggerMailings::Letter::IncorrectMailingSettingsError] ошибка, если неизвестен заголовок
    # @private
    def subject
      settings['title'] || (raise IncorrectMailingSettingsError.new('Undefined title'))
    end

    # Адрес отправителя
    #
    # @return [String] адрес отправителя
    # @raise [TriggerMailings::Letter::IncorrectMailingSettingsError] ошибка, если неизвестен адрес оптравителя
    # @private
    def send_from
      @subscription.shop.trigger_mailing.mailing_settings['send_from'] || (raise IncorrectMailingSettingsError.new('Undefined send_from'))
    end

    # Тело письма
    #
    # @return [String] тело письма
    # @private
    def body
      @body
    end
  end
end
