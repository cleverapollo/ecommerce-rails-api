class WebPush::DigestMessage

  class IncorrectSettingsError < StandardError; end
  class NotEnoughMoney < StandardError; end

  attr_accessor :client, :shop, :digest, :batch, :message, :settings, :body, :safari_pusher, :test

  # Инициализиация сообщения
  # @param client [Client]
  # @param digest [WebPushDigest]
  # @param batch [WebPushDigestBatch]
  # @param safari_pusher [Grocer]
  # @param test [Boolean] Тестовая отправка?
  def initialize(client, digest, batch, safari_pusher = nil, test = false)
    @client = client
    @shop = @client.shop
    @digest = digest
    @batch = batch
    @safari_pusher = safari_pusher
    @test = test

    # Проверяем наличие баланса у магазина
    if !test && @shop.web_push_balance < 1
      raise NotEnoughMoney
    end

    unless test
      @message = client.web_push_digest_messages.create!(
          web_push_digest: digest,
          web_push_digest_batch: batch,
          shop: client.shop,
      ).reload
    end
    @body = generate_body
  end


  # Отправляет уведомление
  def send
    # Если ни одно сообщение не было доставлено до клиента, удаляем запись из базы
    unless WebPush::Sender.send(client, shop, body, safari_pusher, test)
      @message.update(unsubscribed: true) unless @message.nil?
    end
  end

  private

  # Создает JSON-объект для отправки web push сообщения
  # @return JSON
  def generate_body
    {
        title:  digest.subject,
        body:   digest.message,
        icon:   digest.fetch_picture_url,
        url:    UrlParamsHelper.add_params_to(digest.url, {
            utm_source: 'rees46',
            utm_medium: 'web_push_digest',
            utm_campaign: "rees46_web_push_#{digest.id}",
            recommended_by: 'web_push_digest',
            rees46_web_push_digest_code: message.nil? ? 'test' : message.code
        })
    }
  end
end
