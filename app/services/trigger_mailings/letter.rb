module TriggerMailings
  ##
  # Класс, реализующий триггерное письмо
  #
  class Letter
    class IncorrectMailingSettingsError < StandardError; end
    class EmptyProductsCollectionError < StandardError; end

    # @return [Shop]
    attr_accessor :shop
    # @return [Client]
    attr_accessor :client
    # @return [TriggerMailings::Triggers::Base]
    attr_accessor :trigger
    attr_accessor :body
    attr_accessor :text

    # @return [TriggerMail]
    attr_accessor :trigger_mail
    # @return [ShopEmail]
    attr_accessor :shop_email
    # @return [Hash]
    attr_accessor :data

    # Конструктор
    # @param client [Client] пользователь магазина
    # @param trigger [TriggerMailings::Triggers::Base] триггер
    def initialize(client, trigger)
      @client = client
      @shop = @client.shop
      self.shop_email = ShopEmail.fetch(@shop, @client.email, result: true)
      @trigger = trigger
      @mailings_settings = Slavery.on_slave { @shop.mailings_settings }
      @trigger_mail = client.trigger_mails.create!(
        mailing: trigger.mailing,
        shop: client.shop,
        trigger_data: {
          trigger: trigger.to_json
        }
      ).reload
      @body = generate_liquid_letter_body
      self.text = text_version
    end

    # Отправить сформированное письмо
    def send
      email = client.email
      Mailings::SignedEmail.compose(@shop, to: email,
                                    subject: trigger.settings[:subject],
                                    from: trigger.settings[:send_from],
                                    body: @body,
                                    text: text,
                                    type: 'trigger',
                                    code: trigger_mail.code,
                                    unsubscribe_url: unsubscribe_url(shop_email),
                                    list_id: "<trigger shop-#{@shop.id} type-#{trigger.mailing.trigger_type} date-#{Date.current.strftime('%Y-%m-%d')}>",
                                    feedback_id: "shop#{@shop.id}:mailing_#{trigger.mailing.trigger_type}:trigger:rees46mailer").deliver_now
    end

    private

    # @param [ShopEmail] shop_email
    def unsubscribe_url(shop_email)
      Routes.unsubscribe_subscriptions_url(type: 'trigger', code: shop_email.try(:code) || 'test', host: Rees46::HOST, shop_id: self.shop.uniqid, mail_code: trigger_mail.code)
    end

    def generate_liquid_letter_body

      self.data = {
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
                       trigger.source_items.map { |item| item_for_letter(item, client.location, trigger.settings[:images_dimension]) }
                     else
                       []
                     end
      RecommendationsRequest.report do |r|
        recommendations = trigger.recommendations(recommendations_count)
        data[:recommended_items] = recommendations.map { |item| item_for_letter(item, client.location, trigger.settings[:images_dimension]) }
        r.shop = @shop
        r.recommender_type = 'trigger_mail'
        r.recommendations = recommendations.map(&:uniqid)
        r.user_id = client.user.present? ? client.user.id : 0
      end

      # Товаров может и не быть и в этом случае уходят пустые письма.
      # Поэтому вызываем ошибку и перехватываем ее в обработчике рассылки ClientProcessor
      raise EmptyProductsCollectionError if data[:recommended_items].size == 0 && trigger.code != 'DoubleOptIn'

      if @shop.fetch_logo_url.present?
        data[:logo_url] = @shop.fetch_logo_url
      end

      data[:utm_params] = Mailings::Composer.utm_params(trigger_mail, as: :string)
      data[:footer] = Mailings::Composer.footer(email: client.email, tracking_url: trigger_mail.tracking_url, unsubscribe_url: unsubscribe_url(shop_email))
      data[:email] = client.email
      data[:tracking_url] = trigger_mail.tracking_url
      data[:unsubscribe_url] = unsubscribe_url(shop_email)
      data[:tracking_pixel] = "<img src='#{data[:tracking_url]}' alt=''></img>"

      if trigger.code == 'RecentlyPurchased' && liquid_template.scan('{% if reputation %}').any?
        plan = @shop.subscription_plans.reputation.first

        if plan && plan.paid? && @shop.reputations_enabled?

          order = trigger.additional_info[:order]
          if order.present?
            order.update(reputation_key: Digest::MD5.hexdigest(order.id.to_s)) unless order.reputation_key
            reputation_key = order.reputation_key
          else
            reputation_key = 'test'
          end

          data[:reputation] = @shop.reputations_enabled
          (1..5).each do |rate|
            data[:"rate_#{rate}_url"] = "#{Rees46.site_url}/shops/#{@shop.uniqid}/reputations/new?order_id=#{reputation_key}&rating=#{rate}"
          end
        else
          data[:reputation] = false
        end
      end

      if trigger.code == 'DoubleOptIn'
        data[:confirmation_email_url] = "#{Rees46.site_url}/confirm-email?shop=#{@shop.uniqid}&client=#{Base16.encode16([@client.id, @client.email].join(' '))} "
        trigger.client.shop_email.email_confirmed = false if trigger.client.shop_email.email_confirmed.nil?
        trigger.client.shop_email.save if trigger.client.shop_email.changed?
      end

      template = Liquid::Template.parse liquid_template
      template.render data.deep_stringify_keys
    end

    # Формирует текстовую версию
    def text_version
      template = Liquid::Template.parse (trigger.settings[:text_template].present? ? trigger.settings[:text_template].dup : '')
      template.render data.deep_stringify_keys
    end


    # Обертка над товаром для отображения в письме
    # @param [Item] item товар
    # @param [String] location Идентификатор локации, в которой находится клиент
    # @raise [Mailings::NotWidgetableItemError] исключение, если у товара нет необходимых параметров
    # @return [Hash] обертка
    def item_for_letter(item, location, images_dimension = nil)
      raise Mailings::NotWidgetableItemError.new(item) unless item.widgetable?
      {
        name: item.name,
        description: item.description.to_s,
        price_formatted: ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(location), precision: 0, delimiter: " "),
        oldprice_formatted: item.oldprice.present? ? ActiveSupport::NumberHelper.number_to_rounded(item.oldprice, precision: 0, delimiter: " ") : nil,
        price: item.price_at_location(location).to_i,
        price_full: item.price_at_location(location).to_f,
        price_full_formatted: ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(location), precision: 2, delimiter: ' '),
        oldprice: item.oldprice.to_i,
        url: UrlParamsHelper.add_params_to(item.url, Mailings::Composer.utm_params(trigger_mail).merge(r46_merger: Base64.encode64(@client.email.to_s).strip)),
        image_url: (images_dimension ? item.resized_image_by_dimension(images_dimension) : item.image_url),
        currency: self.shop.currency,
        id: item.uniqid.to_s,
        barcode: item.barcode.to_s,
        brand: item.brand.to_s,
        amount: item.amount || 1,
        leftovers: item.leftovers,
      }
    end
  end
end
