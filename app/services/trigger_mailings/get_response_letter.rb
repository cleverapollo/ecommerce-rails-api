module TriggerMailings
  class GetResponseLetter < TriggerMailings::Letter

    class GetResponseApiError < StandardError; end

    attr_accessor :api

    def initialize(client, trigger, get_response_client)
      @client = client
      @shop = @client.shop
      @trigger = trigger
      @api = get_response_client
      @trigger_mail = client.trigger_mails.create!(
        mailing: trigger.mailing,
        shop: client.shop,
        trigger_data: {
          trigger: trigger.to_json
        }
      ).reload
    end

    # Уведомляем API GetResponse о том, что сработал новый триггер
    def send
      api.add_contact(client.email, trigger.mailing.trigger_type, trigger_mail.code)
    end


  end
end
