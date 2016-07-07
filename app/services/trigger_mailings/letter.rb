module TriggerMailings
  ##
  # Класс, реализующий триггерное письмо
  #
  class Letter
    class IncorrectMailingSettingsError < StandardError; end

    attr_accessor :client, :trigger, :trigger_mail, :body

    # Конструктор
    # @param client [Client] пользователь магазина
    # @param trigger [TriggerMailings::Triggers::Base] триггер
    def initialize(client, trigger)
      @client = client
      @shop = @client.shop
      @trigger = trigger
      @mailings_settings = @shop.mailings_settings
      @trigger_mail = client.trigger_mails.create!(
        mailing: trigger.mailing,
        shop: client.shop,
        trigger_data: {
          trigger: trigger.to_json
        }
      ).reload
      @body = @mailings_settings.template_liquid? ? generate_liquid_letter_body : generate_letter_body
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
                                    code: trigger_mail.code,
                                    list_id: "<trigger shop-#{@shop.id} type-#{trigger.mailing.trigger_type} date-#{Date.current.strftime('%Y-%m-%d')}>" ).deliver_now
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

      # Вставляем в шаблон параметры "исходного" товара или "исходных, если их больше"
      if trigger.source_items.present? && trigger.source_items.any? && result['{{ source_item }}'].present?

        source_items_count = trigger.settings[:template].scan(/{{ source_item }}/).count

        # Несколько товаров
        trigger.source_items.take(source_items_count).each do |item|

          source_item_template = trigger.settings[:source_item_template].dup
          decorated_source_item = item_for_letter(item, client.location)
          decorated_source_item.each do |key, value|
            if value
              source_item_template.gsub!("{{ #{key} }}", value.to_s)
              source_item_template.gsub!(/\{\{\s+name\s+limit=([0-9]+)\s+\}\}/) { limit = "#{$1}".to_i; (value[0,limit] + '...') } if key.to_s == 'name'
            end
          end
          result['{{ source_item }}'] = source_item_template

        end

        # Удаляем лишние заглушки
        result.gsub!('{{ source_item }}', '')

      elsif trigger.source_item.present?

        # Один товар

        decorated_source_item = item_for_letter(trigger.source_item, client.location)
        decorated_source_item.each do |key, value|
          if value
            result.gsub!("{{ source_item.#{key} }}", value.to_s)
            result.gsub!(/\{\{\s+source_item.name\s+limit=([0-9]+)\s+\}\}/) { limit = "#{$1}".to_i; (value[0,limit] + '...') } if key.to_s == 'name'
          end
        end
      end

      RecommendationsRequest.report do |r|
        recommendations = trigger.recommendations(recommendations_count)

        # Проходимся по рекомендациям и вставляем их в шаблон
        recommendations.each do |recommended_item|
          decorated_recommended_item = item_for_letter(recommended_item, client.location)

          recommended_item_template = trigger.settings[:item_template].dup
          decorated_recommended_item.each do |key, value|
            if value
              recommended_item_template.gsub!("{{ #{key} }}", value.to_s)
              recommended_item_template.gsub!(/\{\{\s+name\s+limit=([0-9]+)\s+\}\}/) { limit = "#{$1}".to_i; (value[0,limit] + '...') } if key.to_s == 'name'
            end
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

      # Cтавим логотип
      if MailingsSettings.where(shop_id: @shop.id).first.fetch_logo_url.blank? && (result.include?'{{ logo_url }}')
        result.sub!(/<img(.*?)<\/tr>/m," ")
      else
        result.gsub!('{{ logo_url }}', MailingsSettings.where(shop_id: @shop.id).first.fetch_logo_url)
      end

      # Ставим utm-параметры
      result.gsub!('{{ utm_params }}', Mailings::Composer.utm_params(trigger_mail, as: :string))

      # В конце прицепляем футер на отписку
      footer = Mailings::Composer.footer(email: client.email,
                                         tracking_url: trigger_mail.tracking_url,
                                         unsubscribe_url: client.trigger_unsubscribe_url)
      result.gsub!('{{ footer }}', footer)

      # Ставим ссылку eKomi, если нужно
      if result.scan('{{ feedback_button_link }}').any? && trigger.code == 'RecentlyPurchased'
        if @shop.ekomi?
          product_ids = []
          trigger.additional_info[:order].order_items.each do |order_item|
            item = order_item.item
            if item && item.name.present? && item.uniqid.present?
              item_additional_params = {links: [rel: 'canonical', type: 'text/html', href: item.url] }
              item_additional_params[:image_url] = item.image_url if item.image_url.present?
              begin
                Integrations::EKomi.new(@shop.ekomi_id, @shop.ekomi_key).put_product(item.uniqid, item.name, item_additional_params)
                product_ids << item.uniqid
              rescue => e
                Rollbar.error e
              end
            end
          end
          begin
            feedback_button_link = Integrations::EKomi.new(@shop.ekomi_id, @shop.ekomi_key).put_order(trigger.additional_info[:order], product_ids)['link']
          rescue => e
            Rollbar.error e
          end
        else
          feedback_button_link = "#{@shop.url}/?#{Mailings::Composer.utm_params(trigger_mail, as: :string)}"
        end
        result.gsub!('{{ feedback_button_link }}', feedback_button_link)
      end

      result
    end


    def generate_liquid_letter_body

      data = {
          shop_url: @shop.url,
          feedback_button_link: nil,
          utm_params: '',
          source_items: [],
          recommended_items: [],
          logo_url: nil,
          footer: nil
      }

      liquid_template = trigger.settings[:liquid_template].dup
      recommendations_count = trigger.settings[:amount_of_recommended_items]
      data[:source_items] = if trigger.source_items.present? && trigger.source_items.any?
                       trigger.source_items.map { |item| item_for_letter(item, client.location, trigger.settings[:image_width], trigger.settings[:image_height]) }
                     else
                       []
                     end
      RecommendationsRequest.report do |r|
        recommendations = trigger.recommendations(recommendations_count)
        data[:recommended_items] = recommendations.map { |item| item_for_letter(item, client.location, trigger.settings[:image_width], trigger.settings[:image_height]) }
        r.shop = @shop
        r.recommender_type = 'trigger_mail'
        r.recommendations = recommendations.map(&:uniqid)
        r.user_id = client.user.present? ? client.user.id : 0
      end

      mailings_settings = MailingsSettings.find_by(shop_id: @shop.id)
      if mailings_settings && mailings_settings.fetch_logo_url.present?
        data[:logo_url] = mailings_settings.fetch_logo_url
      end

      data[:utm_params] = Mailings::Composer.utm_params(trigger_mail, as: :string)
      data[:footer] = Mailings::Composer.footer(email: client.email, tracking_url: trigger_mail.tracking_url, unsubscribe_url: client.trigger_unsubscribe_url)

      if liquid_template.scan('{{ feedback_button_link }}').any? && trigger.code == 'RecentlyPurchased'
        if @shop.ekomi?
          product_ids = []
          trigger.additional_info[:order].order_items.each do |order_item|
            item = order_item.item
            if item && item.name.present? && item.uniqid.present?
              item_additional_params = {links: [rel: 'canonical', type: 'text/html', href: item.url] }
              item_additional_params[:image_url] = item.image_url if item.image_url.present?
              begin
                Integrations::EKomi.new(@shop.ekomi_id, @shop.ekomi_key).put_product(item.uniqid, item.name, item_additional_params)
                product_ids << item.uniqid
              rescue
              end
            end
          end
          data[:feedback_button_link] = Integrations::EKomi.new(@shop.ekomi_id, @shop.ekomi_key).put_order(trigger.additional_info[:order], product_ids)['link']
        else
          data[:feedback_button_link] = "#{@shop.url}/?#{Mailings::Composer.utm_params(trigger_mail, as: :string)}"
        end
      end

      template = Liquid::Template.parse liquid_template
      template.render data.deep_stringify_keys

    end


    # Обертка над товаром для отображения в письме
    # @param [Item] товар
    # @param location [String] Идентификатор локации, в которой находится клиент
    # @param width [Integer] Ширина картинки для ресайза
    # @param height [Integer] Высота картинки для ресайза
    # @raise [Mailings::NotWidgetableItemError] исключение, если у товара нет необходимых параметров
    # @return [Hash] обертка
    def item_for_letter(item, location, width = nil, height = nil)
      raise Mailings::NotWidgetableItemError.new(item) unless item.widgetable?
      {
        name: item.name.truncate(40),
        description: item.description.to_s,
        price_formatted: ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(location), precision: 0, delimiter: " "),
        oldprice_formatted: item.oldprice.present? ? ActiveSupport::NumberHelper.number_to_rounded(item.oldprice, precision: 0, delimiter: " ") : nil,
        price: item.price_at_location(location).to_i,
        oldprice: item.oldprice.to_i,
        url: UrlParamsHelper.add_params_to(item.url, Mailings::Composer.utm_params(trigger_mail)),
        image_url: (width && height ? item.resized_image(width, height) : item.image_url),
        currency: item.shop.currency,
        id: item.uniqid.to_s,
        barcode: item.barcode.to_s,
        brand: item.brand.to_s,
        amount: item.amount || 1
      }
    end
  end
end
