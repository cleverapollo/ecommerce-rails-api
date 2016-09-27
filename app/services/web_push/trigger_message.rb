class WebPush::TriggerMessage

  class IncorrectSettingsError < StandardError; end

  attr_accessor :client, :shop, :trigger, :message, :settings, :body

  # Инициализация сообщения
  # @param trigger
  # @param client [Client]
  # @param safari_pusher [Grocer]
  def initialize(trigger, client, safari_pusher = nil)
    @client = client
    @shop = @client.shop
    @trigger = trigger
    @message = client.web_push_trigger_messages.create!(
        web_push_trigger: trigger.mailing,
        shop: client.shop,
        trigger_data: {
            trigger: trigger.to_json
        }
    ).reload
    @body = generate_body
  end


  # Отправляет уведомление
  def send
    WebPush::Sender.send client, shop, body
  end

  private

  # Создает JSON-объект для отправки web push сообщения
  # @return JSON
  def generate_body
    JSON.generate({
        title:  trigger.settings[:subject],
        body:   trigger.settings[:message],
        icon:   trigger.items.first.image_url,
        url:    UrlParamsHelper.add_params_to(trigger.items.first.url, {
            utm_source: 'rees46',
            utm_medium: 'web_push_trigger',
            utm_campaign: trigger.mailing.trigger_type,
            recommended_by: 'web_push_trigger',
            rees46_web_push_trigger_code: message.code
        })
    })
  end



end