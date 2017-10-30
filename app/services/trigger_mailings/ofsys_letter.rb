module TriggerMailings
  class OfsysLetter < TriggerMailings::Letter
    include HTTParty

    class OfsysError < StandardError; end

    HOOK_URL = "https://emailexperts.ru/rees46/webhook.php"

    # attr_accessor :data

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
    end

    def send
      Timeout::timeout(2) {
        response = self.class.post(
          "#{HOOK_URL}",
          body: generate_letter_body,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => Rees46::USER_AGENT
          }
        )
        true
      }
    rescue Timeout::Error => e
      Rollbar.warning(e, "Timeout Ofsys Test Trigger", shop_id: @shop.id, client_id: client.id)
      false
    end

    private

    def generate_letter_body
      data = {
          trigger_type: trigger.class.to_s.gsub(/\A(.+::)(.+)\z/, '\2').underscore,
          email: client.email,
          shop_key: @shop.uniqid,
          source_items: [],
          recommended_items: [],
      }
      data[:source_items] = if trigger.source_items.present? && trigger.source_items.any?
        trigger.source_items.map { |item| item_for_letter(item, client.location) }
      else
        []
      end

      RecommendationsRequest.report do |r|
        recommendations = trigger.recommendations(trigger.settings[:amount_of_recommended_items])
        data[:recommended_items] = recommendations.map { |item| item_for_letter(item, client.location) }
        r.shop = @shop
        r.recommender_type = 'trigger_mail'
        r.recommendations = recommendations.map(&:uniqid)
        r.user_id = client.user.present? ? client.user.id : 0
      end

      data.to_json
    end

    # Обертка над товаром для отображения в письме
    # @param [Item] товар
    # @param location [String] Идентификатор локации, в которой находится клиент
    # @raise [Mailings::NotWidgetableItemError] исключение, если у товара нет необходимых параметров
    # @return [Hash] обертка
    def item_for_letter(item, location)
      raise Mailings::NotWidgetableItemError.new(item) unless item.widgetable?
      {
        id: item.uniqid.to_s,
        name: item.name,
        description: item.description.to_s,
        barcode: item.barcode.to_s,
        price: item.price_at_location(location).to_i,
        price_formatted: ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(location), precision: 0, delimiter: " "),
        price_full: item.price_at_location(location).to_f,
        price_full_formatted: ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(location), precision: 2, delimiter: " "),
        oldprice: item.oldprice.to_i,
        oldprice_formatted: item.oldprice.present? ? ActiveSupport::NumberHelper.number_to_rounded(item.oldprice, precision: 0, delimiter: " ") : nil,
        currency: item.shop.currency,
        url: UrlParamsHelper.add_params_to(item.url, Mailings::Composer.utm_params(trigger_mail)),
        image_url: item.image_url,
        brand: item.brand.to_s,
        amount: item.amount || 1
      }
    end
  end
end
