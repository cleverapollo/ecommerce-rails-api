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
      @body = generate_liquid_letter_body
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
                                    list_id: "<trigger shop-#{@shop.id} type-#{trigger.mailing.trigger_type} date-#{Date.current.strftime('%Y-%m-%d')}>",
                                    feedback_id: "shop#{@shop.id}:mailing_#{trigger.mailing.trigger_type}:trigger:rees46mailer").deliver_now
    end

    private

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
      if @shop.fetch_logo_url.present?
        data[:logo_url] = @shop.fetch_logo_url
      end

      data[:utm_params] = Mailings::Composer.utm_params(trigger_mail, as: :string)
      data[:footer] = Mailings::Composer.footer(email: client.email, tracking_url: trigger_mail.tracking_url, unsubscribe_url: client.trigger_unsubscribe_url)
      data[:email] = client.email
      data[:tracking_url] = trigger_mail.tracking_url
      data[:unsubscribe_url] = client.trigger_unsubscribe_url
      data[:tracking_pixel] = "<img src='#{data[:tracking_url]}' alt=''></img>"

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
        name: item.name,
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
