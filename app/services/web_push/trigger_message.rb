class WebPush::TriggerMessage

  class IncorrectSettingsError < StandardError; end
  class NotEnoughMoney < StandardError; end

  attr_accessor :client, :shop, :trigger, :message, :settings, :body, :safari_pusher

  # Инициализация сообщения
  # @param trigger [WebPush::Triggers::Base]
  # @param client [Client]
  # @param safari_pusher [Grocer]
  def initialize(trigger, client, safari_pusher = nil)
    @client = client
    @shop = @client.shop
    @trigger = trigger
    @safari_pusher = safari_pusher

    # Проверяем наличие баланса у магазина
    if @shop.web_push_balance < 1
      raise NotEnoughMoney
    end

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
    WebPush::Sender.send(client, shop, body, safari_pusher)
  end

  private

  # Создает объект для отправки web push сообщения
  # @return [Hash]
  def generate_body
    {
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
    }
  end



end