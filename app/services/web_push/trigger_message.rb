class WebPush::TriggerMessage

  class IncorrectSettingsError < StandardError; end
  class NotEnoughMoney < StandardError; end

  attr_accessor :client, :shop, :trigger, :message, :settings, :body, :safari_pusher, :test

  # Инициализация сообщения
  # @param trigger [WebPush::Triggers::Base]
  # @param client [Client]
  # @param safari_pusher [Grocer]
  # @param test [Boolean] Тестовая отправка?
  def initialize(trigger, client, safari_pusher = nil, test = false)
    @client = client
    @shop = @client.shop
    @trigger = trigger
    @safari_pusher = safari_pusher
    @test = test

    # Проверяем наличие баланса у магазина
    if !test && (@shop.web_push_balance < 1 || (!@shop.subscription_plans.find_by(product: 'trigger.webpush') || !@shop.subscription_plans.find_by(product: 'trigger.webpush').paid?))
      raise NotEnoughMoney
    end

    # Если отправляем реальный триггер, то создаем сообщение
    unless test
      @message = client.web_push_trigger_messages.create!(
          web_push_trigger: trigger.mailing,
          shop: client.shop,
          trigger_data: {
              trigger: trigger.to_json
          }
      ).reload
    end
    @body = generate_body
  end


  # Отправляет уведомление
  def send
    # Если ни одно сообщение не было доставлено до клиента, удаляем запись из базы
    unless WebPush::Sender.send(client, shop, body, safari_pusher, test)
      @message.destroy unless @message.nil?
    end
  end

  private

  # Создает объект для отправки web push сообщения
  # @return [Hash]
  def generate_body
    {
        title:  trigger.settings[:subject],
        body:   trigger.settings[:message],
        icon:   trigger.items.first.resized_image_by_dimension('220x220'),
        url:    UrlParamsHelper.add_params_to(trigger.items.first.url, {
            rees46_source: 'web_push_trigger',
            rees46_campaign: trigger.mailing.trigger_type,
            recommended_by: 'web_push_trigger',
            rees46_web_push_trigger_code: message.nil? ? nil : message.code
        })
    }
  end



end
